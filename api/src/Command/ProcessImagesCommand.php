<?php declare(strict_types=1);

namespace App\Command;

use App\Command\Concern\ReportsDuration;
use App\Contract\ImageJobHandlerInterface;
use App\Repository\ImageJobQueueRepository;
use Psr\Container\ContainerExceptionInterface;
use Psr\Container\ContainerInterface;
use Psr\Container\NotFoundExceptionInterface;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;
use Symfony\Component\DependencyInjection\Attribute\AutowireLocator;
use Symfony\Component\Process\PhpExecutableFinder;
use Symfony\Component\Process\Process;
use function assert;
use function is_string;
use function sprintf;

#[AsCommand(
    name: 'api:process-images',
    description: 'Reset stuck image jobs and run a worker pool to drain the queue',
    usages: ['mtg']
)]
class ProcessImagesCommand extends Command
{
    use ReportsDuration;

    private const int POLL_INTERVAL_MICROSECONDS = 200000; // 200ms
    private const int BATCH_SIZE = 100;

    public function __construct(
        private readonly string $projectDir,
        private readonly int $workerLimit,
        private readonly ImageJobQueueRepository $queue,
        #[AutowireLocator('api.image_job_handler', indexAttribute: 'game')]
        private readonly ContainerInterface $handlers,
    ) {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this
            ->addArgument('game', InputArgument::REQUIRED, 'Game code to process.')
            ->addOption('batch-size', null, InputOption::VALUE_REQUIRED, 'Batch size each worker processes', (string) self::BATCH_SIZE)
        ;
    }

    /**
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
            $io->error(sprintf('No image job handler registered for game "%s".', $game));

            return Command::FAILURE;
        }
        $handler = $this->handlers->get($game);
        assert($handler instanceof ImageJobHandlerInterface);

        // Set configuration
        /** @var int $workerLimit */
        $workerLimit = max(1, $this->workerLimit);
        $batchSizeOption = $input->getOption('batch-size');
        assert(is_string($batchSizeOption));
        $batchSize = max(1, (int) $batchSizeOption);

        // Dispatch workers and log progress
        $io->section(sprintf('%s (worker limit: %d)', $game, $workerLimit));
        $reset = $this->queue->resetStuck([$game]);
        if ($reset > 0) {
            $io->writeln(sprintf('Reset %d stuck job(s) back to pending', $reset));
        }

        $start = microtime(true);
        $this->drain($game, $workerLimit, $batchSize, $io);
        $io->comment(sprintf('%d finished in %s', $game, $this->formatDuration(microtime(true) - $start)));

        $this->reportDuration($io);

        return Command::SUCCESS;
    }

    private function drain(string $game, int $workerLimit, int $batchSize, SymfonyStyle $io): void
    {
        $phpBinary = new PhpExecutableFinder()->find();
        /** @var string $php */
        $php = $phpBinary ?: 'php';
        $console = $this->projectDir . '/bin/console';

        $initial = $this->queue->progress($game);
        if ($initial['total'] === 0) {
            $io->writeln(sprintf('No image jobs found for game "%s".', $game));
            return;
        }

        $bar = $io->createProgressBar($initial['total']);
        $bar->setFormat(' %current%/%max% completed (%failed% failed) [%bar%] %percent:3s%%  %elapsed:6s% ETA: %remaining:-6s%');
        $bar->setMessage((string)$initial['failed'], 'failed');
        $bar->start($initial['total'], $initial['completed']);

        /** @var Process[] $running */
        $running = [];
        /** @var string[] $warnings */
        $warnings = [];

        while (true) {
            foreach ($running as $i => $process) {
                if ($process->isRunning()) {
                    continue;
                }
                if (!$process->isSuccessful()) {
                    $warnings[] = trim($process->getErrorOutput());
                }
                unset($running[$i]);
            }
            $running = array_values($running);

            while (count($running) < $workerLimit && $this->queue->countPending($game) > 0) {
                $process = new Process([$php, $console, 'api:process-image-batch', $game, (string) $batchSize], $this->projectDir);
                $process->setTimeout(0);
                $process->start();
                $running[] = $process;
            }

            $progress = $this->queue->progress($game);
            $bar->setMessage((string)$progress['failed'], 'failed');
            $bar->setProgress($progress['completed']);

            if (empty($running) && $this->queue->countPending($game) === 0) {
                break;
            }

            usleep(self::POLL_INTERVAL_MICROSECONDS);
        }

        $bar->finish();
        $io->newLine();

        foreach ($warnings as $warning) {
            $io->warning(sprintf('A worker exited with an error: %s.', $warning));
        }
    }
}
