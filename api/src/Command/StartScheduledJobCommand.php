<?php declare(strict_types=1);

namespace App\Command;

use App\Service\AdminJobService;
use DateTimeImmutable;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

/**
 * Waits until a scheduled admin job is due, then starts it, or leaves it first in line when
 * another job is running then ({@see AdminJobService::enqueue()} starts this for every scheduled
 * job). Checks the job every minute, so it gives up as soon as the job is taken out of the queue.
 *
 * Only a helper: when it doesn't survive (a restart), the job still starts on the next visit to
 * the admin's Sync page, or from cron with `api:admin:start-scheduled --due`.
 */
#[AsCommand(name: 'api:admin:start-scheduled', description: 'Start scheduled admin jobs when they are due. Admin jobs start it; --due is for cron.')]
final class StartScheduledJobCommand extends Command
{
    private const int CHECK_EVERY_SECONDS = 60;

    public function __construct(private readonly AdminJobService $jobs)
    {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this
            ->addArgument('id', InputArgument::OPTIONAL, 'Job id to wait for.')
            ->addOption('due', null, null, 'Start whatever is due now and exit, without waiting (for cron).');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $id = $input->getArgument('id');
        if ($input->getOption('due') || !is_string($id)) {
            $this->jobs->startNext();

            return Command::SUCCESS;
        }

        while (true) {
            $job = $this->jobs->find($id);
            if ($job === null || !$this->jobs->isQueued($job)) {
                return Command::SUCCESS; // Taken out of the queue, or already started
            }

            $runAt = isset($job['runAt']) ? new DateTimeImmutable($job['runAt']) : new DateTimeImmutable();
            $wait = $runAt->getTimestamp() - time();
            if ($wait <= 0) {
                $this->jobs->startNext(); // Starts it, unless a job is running: then the runner does

                return Command::SUCCESS;
            }

            sleep(min($wait, self::CHECK_EVERY_SECONDS));
        }
    }
}
