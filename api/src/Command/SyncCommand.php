<?php
declare(strict_types=1);

namespace App\Command;

use App\Command\Concern\ReportsDuration;
use App\Contract\ImportServiceInterfaceV1;
use App\Enum\IconImportType;
use App\Enum\ImageImportType;
use App\Repository\ImageJobQueueRepository;
use LogicException;
use Psr\Container\ContainerExceptionInterface;
use Psr\Container\ContainerInterface;
use Psr\Container\NotFoundExceptionInterface;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Exception\ExceptionInterface;
use Symfony\Component\Console\Helper\ProgressIndicator;
use Symfony\Component\Console\Input\ArrayInput;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;
use Symfony\Component\DependencyInjection\Attribute\AutowireLocator;
use function assert;
use function is_bool;
use function is_string;
use function sprintf;

/**
 * Runs a game's full sync pipeline in dependency order: sets, then set icons and cards, then
 * card images last. Replaces per-step game commands for day-to-day use — everything but images
 * takes minutes, so there's little value in running the steps separately.
 */
#[AsCommand(name: 'api:sync', description: 'Sync all mtg data to the DB and (optionally) import card images.')]
class SyncCommand extends Command
{
    use ReportsDuration;

    private const int DEFAULT_BATCH_SIZE = 100;
    private const int MAX_IMAGE_ATTEMPTS = 3;

    public function __construct(
        #[AutowireLocator('api.game_service', indexAttribute: 'game')]
        private readonly ContainerInterface $handlers,
        private readonly ImageJobQueueRepository $imageJobQueue,
    ) {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this
            ->addArgument('game', InputArgument::REQUIRED, 'Game code to process.')
            ->addOption('skip-images', null, InputOption::VALUE_NONE, 'Skip all image imports entirely, queuing nothing (default: new images only)')
            ->addOption('postpone-images', null, InputOption::VALUE_NONE, 'Queue new images but don\'t download them now; run api:process-images later (default: new images only)')
            ->addOption('all-images', null, InputOption::VALUE_NONE, '(Re)import all images (default: new images only), including set icons')
            ->addOption('all-icons', null, InputOption::VALUE_NONE, '(Re)import all set icons (default: new icons only); set icons can\'t be skipped entirely')
            ->addOption('batch-size', null, InputOption::VALUE_REQUIRED, 'Batch size each images worker processes (default:100)')
        ;
    }

    /**
     * @throws ExceptionInterface
     * @throws ContainerExceptionInterface
     * @throws NotFoundExceptionInterface
     */
    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);
        $this->startDuration();

        // Validate argument 'game' has a valid handler
        $game = $input->getArgument('game');
        assert(is_string($game));

        if (!$this->handlers->has($game)) {
            $io->error(sprintf('No game service registered for game "%s".', $game));

            return Command::FAILURE;
        }
        $handler = $this->handlers->get($game);
        assert($handler instanceof ImportServiceInterfaceV1);

        // Validate there's only one or none image arguments
        $skipImages = $input->getOption('skip-images');
        $postponeImages = $input->getOption('postpone-images');
        $allImages = $input->getOption('all-images');
        $allIcons = $input->getOption('all-icons');
        assert(is_bool($skipImages) && is_bool($postponeImages) && is_bool($allImages) && is_bool($allIcons));

        if (($skipImages ? 1 : 0) + ($postponeImages ? 1 : 0) + ($allImages ? 1 : 0) > 1) {
            $io->error('Options "--skip-images", "--postpone-images" and "--all-images" cannot be used together.');

            return Command::FAILURE;
        }

        $imageImportType = match (true) {
            $skipImages => ImageImportType::SkipAll,
            $allImages => ImageImportType::All,
            // --postpone-images still queues new images (just like the default) — it only
            // affects whether this command processes that queue immediately, below.
            default => ImageImportType::NewOnly,
        };
        // Set icons can't be skipped entirely, only limited to new ones. --all-images implies a
        // full icon resync too; --all-icons controls icons independently of card images.
        $iconImportType = ($allImages || $allIcons) ? IconImportType::All : IconImportType::NewOnly;

        // Validate the batch size argument is valid
        $batchSizeOption = $input->getOption('batch-size');
        assert($batchSizeOption === null || is_string($batchSizeOption));

        $batchSize = self::DEFAULT_BATCH_SIZE;
        if ($batchSizeOption !== null) {
            if ((int) $batchSizeOption < 1 || !ctype_digit($batchSizeOption)) {
                $io->error(sprintf('Option "--batch-size" must be a positive integer, got "%s".', $batchSizeOption));

                return Command::FAILURE;
            }
            $batchSize = (int) $batchSizeOption;
        }

        $application = $this->getApplication();
        if ($application === null) {
            throw new LogicException('No application available to look up sub-commands.');
        }

        // Run sync process
        $io->section('Syncing sets');
        $start = microtime(true);
        $setsIndicator = new ProgressIndicator($output);
        $setsIndicator->start('Syncing sets...');
        $syncedSets = $handler->syncSetInfo($this->progressCallback($setsIndicator, $start, 'set(s) synced'));
        $setsIndicator->finish(sprintf('%d set(s) synced.', $syncedSets));
        $io->writeln(sprintf('Synced %d set(s) in %s.', $syncedSets, $this->formatDuration(microtime(true) - $start)));

        $io->section('Importing set icons');
        $start = microtime(true);
        $iconsIndicator = new ProgressIndicator($output);
        $iconsIndicator->start('Checking set icons...');
        $syncedIcons = $handler->syncSetIcons($iconImportType, $this->progressCallback($iconsIndicator, $start, 'set icon(s) checked'));
        $iconsIndicator->finish(sprintf('%d set icon(s) synced.', $syncedIcons));
        $io->writeln(sprintf('Synced %d set icon(s) in %s.', $syncedIcons, $this->formatDuration(microtime(true) - $start)));

        $io->section('Syncing cards');
        $start = microtime(true);
        $cardsIndicator = new ProgressIndicator($output);
        $cardsIndicator->start('Importing cards...');
        $syncedCards = $handler->syncCardInfo($imageImportType, $this->progressCallback($cardsIndicator, $start, 'card(s) imported'));
        $cardsIndicator->finish(sprintf('%d card(s) imported.', $syncedCards));
        $io->writeln(sprintf('Synced %d card(s) in %s.', $syncedCards, $this->formatDuration(microtime(true) - $start)));

        if ($skipImages) {
            $io->section('Skipping card images');
            $io->writeln('Skipped card image import entirely; nothing was queued (--skip-images).');
        } elseif ($postponeImages) {
            $io->section('Postponing card images');
            $io->writeln(sprintf(
                'New card images were queued but not downloaded. Run "api:process-images %s" to process them later (--postpone-images).',
                $game,
            ));
        } else {
            // Also drains any jobs left pending/failed from a previous run.
            $io->section('Importing card images');
            $start = microtime(true);
            $before = $this->imageJobQueue->progress($game)['completed'];

            $processImagesArgs = ['game' => $game, '--batch-size' => (string) $batchSize];
            if ($allImages) {
                // --all-images re-enqueues existing jobs (see syncCardInfo()'s enqueueBatch()
                // call above), but a claimed job alone can't tell ImageJobHandler *why* it's
                // pending — without --force here too, hasAllSizes() would still skip
                // redownloading any card whose files already exist, silently defeating
                // --all-images for exactly the cards it's meant to fix.
                $processImagesArgs['--force'] = true;
            }

            $attempts = 0;
            do {
                $attempts++;
                $exitCode = $application->find('api:process-images')->run(
                    new ArrayInput($processImagesArgs),
                    $output,
                );
                if ($exitCode !== Command::SUCCESS) {
                    $io->error('Card image import failed.');

                    return Command::FAILURE;
                }

                $imageProgress = $this->imageJobQueue->progress($game);
            } while ($imageProgress['failed'] > 0 && $attempts < self::MAX_IMAGE_ATTEMPTS);

            if ($imageProgress['failed'] > 0) {
                $io->warning(sprintf('%d card image(s) still failed after %d attempt(s).', $imageProgress['failed'], $attempts));
            }
            $io->writeln(sprintf(
                'Imported %d card image(s) in %s.',
                $imageProgress['completed'] - $before,
                $this->formatDuration(microtime(true) - $start),
            ));
        }

        $io->success(sprintf('%s sync completed.', $game));
        $this->reportDuration($io);

        return Command::SUCCESS;
    }

    /**
     * @return callable(int, float): void
     */
    private function progressCallback(ProgressIndicator $indicator, float $start, string $noun): callable
    {
        // ProgressIndicator::advance() self-throttles its redraw, but setMessage() writes
        // immediately every call — without this, a fast loop calling back on every single
        // item (e.g. 1000+ sets/icons in a couple of seconds) floods the output.
        $lastUpdate = 0.0;

        return function (int $count, float $fractionComplete) use ($indicator, $start, $noun, &$lastUpdate): void {
            $now = microtime(true);
            if ($fractionComplete < 1.0 && $now - $lastUpdate < 0.1) {
                return;
            }
            $lastUpdate = $now;

            $message = sprintf('%d %s so far... (%.0f%%', $count, $noun, $fractionComplete * 100);
            if ($fractionComplete > 0.0) {
                $elapsed = $now - $start;
                $eta = $elapsed * (1 - $fractionComplete) / $fractionComplete;
                $message .= sprintf(', ETA %s', $this->formatDuration($eta));
            }
            $message .= ')';

            $indicator->setMessage($message);
            $indicator->advance();
        };
    }
}
