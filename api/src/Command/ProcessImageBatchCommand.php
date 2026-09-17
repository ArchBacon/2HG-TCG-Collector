<?php declare(strict_types=1);

namespace App\Command;

use App\Command\Concern\ReportsDuration;
use App\Repository\ImageJobQueueRepository;
use App\Service\ImageJobHandler;
use Psr\Container\ContainerExceptionInterface;
use Psr\Container\ContainerInterface;
use Psr\Container\NotFoundExceptionInterface;
use Random\RandomException;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;
use Symfony\Component\DependencyInjection\Attribute\AutowireLocator;

#[AsCommand(
    name: 'api:process-image-batch',
    description: 'This command shouldn\'t be ran manually. Run "api:process-images" instead.'
)]
class ProcessImageBatchCommand extends Command
{
    use ReportsDuration;

    public function __construct(
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
            ->addArgument('size', InputArgument::REQUIRED, 'Batch size to process.')
            ->addOption('force', null, InputOption::VALUE_NONE, 'Redownload every claimed image even if it already exists on disk.')
        ;
    }

    /**
     * @throws ContainerExceptionInterface
     * @throws NotFoundExceptionInterface
     * @throws RandomException
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
        assert($handler instanceof ImageJobHandler);

        // Validate argument 'size'
        $batchSize = $input->getArgument('size');
        assert(is_string($batchSize));
        $batchSize = (int) $batchSize;

        $force = (bool) $input->getOption('force');

        $host = gethostname();
        $token = sprintf('%s-%d-%s', $host ?: 'worker', getmypid(), bin2hex(random_bytes(4)));

        $jobs = $this->queue->claimBatch($game, $batchSize, $token);

        $completed = 0;
        $failed = 0;
        foreach ($jobs as $job) {
            try {
                $handler->process($job['cardId'], $job['imageUri'], $force);
                $this->queue->markCompleted($job['id']);
                $completed++;
            } catch (\Throwable $e) {
                $this->queue->markFailed($job['id'], $e->getMessage());
                $failed++;
                $io->error(sprintf('Card "%s" failed: %s', $job['cardId'], $e->getMessage()));
            }
        }

        $io->writeln(\sprintf('%d claimed, %d completed, %d failed.', \count($jobs), $completed, $failed));
        $this->reportDuration($io);

        return $failed > 0 ? Command::FAILURE : Command::SUCCESS;
    }
}
