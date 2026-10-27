<?php declare(strict_types=1);

namespace App\Command;

use App\Service\AdminJobService;
use DateTimeImmutable;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\Process\PhpExecutableFinder;
use Symfony\Component\Process\Process;

use function sprintf;

/**
 * Runs a job from the admin queue ({@see AdminJobService::startNext()}): its console command, with
 * everything it prints appended to the job's log as it comes, and the exit code saved at the end.
 * Stops it when the admin asks ({@see AdminJobService::requestStop()}). Then starts the next job in
 * the queue, if there is one.
 */
#[AsCommand(name: 'api:admin:run-job', description: 'This command shouldn\'t be ran manually. Admin jobs start it.')]
final class RunAdminJobCommand extends Command
{
    /** How often it checks for a stop request (and passes on new output). */
    private const int POLL_INTERVAL_MICROSECONDS = 500000; // 500ms

    public function __construct(
        private readonly AdminJobService $jobs,
        #[Autowire('%kernel.project_dir%')]
        private readonly string $projectDir,
    ) {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this->addArgument('id', InputArgument::REQUIRED, 'Job id.');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $id = $input->getArgument('id');
        assert(is_string($id));

        $job = $this->jobs->find($id);
        if ($job === null) {
            $output->writeln(sprintf('<error>No job %s.</error>', $id));

            return Command::FAILURE;
        }

        $job['pid'] = getmypid() ?: null;
        $job['stoppable'] = true; // This runner checks for stop requests
        $this->jobs->save($job);

        $log = fopen($this->jobs->logPath($id), 'ab');
        assert($log !== false);
        $write = static function (string $text) use ($log): void {
            fwrite($log, $text);
            fflush($log);
        };
        $write(sprintf("$ bin/console %s\n\n", implode(' ', $job['args'])));

        $php = new PhpExecutableFinder()->find() ?: 'php';
        $process = new Process(
            [$php, $this->projectDir . '/bin/console', ...$job['args'], '--no-interaction', '--no-ansi'],
            $this->projectDir,
            ['SHELL_VERBOSITY' => '0'], // Normal output, as in a console; not this runner's
        );
        $process->setTimeout(null); // Syncs with images take hours

        $stopped = false;
        try {
            $process->start(static fn (string $type, string $buffer) => $write($buffer));
            // Checking on it also passes its new output to the callback
            while ($process->isRunning()) {
                usleep(self::POLL_INTERVAL_MICROSECONDS);
                if (!$stopped && $this->jobs->isStopRequested($id)) {
                    $stopped = true;
                    $write("\n\nStopping (asked from the admin)...\n");
                    // SIGTERM, then SIGKILL after 10 seconds; on Windows it ends the whole process tree
                    $process->stop(10);
                }
            }
            $exitCode = $process->getExitCode() ?? Command::FAILURE;
        } catch (\Throwable $e) {
            $write(sprintf("\n%s: %s\n", $e::class, $e->getMessage()));
            $exitCode = Command::FAILURE;
        }

        $write($stopped ? "\nStopped.\n" : sprintf("\nExited with code %d.\n", $exitCode));
        fclose($log);

        // Read again: only the runner writes the job while it runs, but stay safe against stale data
        $job = $this->jobs->find($id) ?? $job;
        $job['exitCode'] = $exitCode;
        $job['stopped'] = $stopped;
        $job['finishedAt'] = new DateTimeImmutable()->format(DATE_ATOM);
        $this->jobs->save($job);
        $this->jobs->clearStopRequest($id);

        $this->jobs->startNext(); // The queue goes on

        return Command::SUCCESS;
    }
}
