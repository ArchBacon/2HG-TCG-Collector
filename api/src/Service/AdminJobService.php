<?php declare(strict_types=1);

namespace App\Service;

use App\Enum\Game;
use DateTimeImmutable;
use DateTimeZone;
use InvalidArgumentException;
use RuntimeException;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\Process\PhpExecutableFinder;
use Symfony\Component\Process\Process;
use Symfony\Component\Uid\Uuid;

use function sprintf;

/**
 * Console commands started from the admin, run in the background so the page can follow their
 * output live. Each job is two files in var/admin-jobs/: `<id>.json` (what runs, when, its exit
 * code) and `<id>.log` (everything it prints), written by `api:admin:run-job`.
 *
 * Only the commands in {@see self::action()} can be run, and one job at a time: the syncs hit the
 * same tables and external APIs. Jobs added while one runs wait in a queue (`startedAt` null) and
 * start in the order they were added: the runner starts the next one when its job ends, and every
 * admin request checks the queue too ({@see self::startNext()}), in case a runner died.
 *
 * A job can be scheduled once for a later time (`runAt`); there's deliberately no repeat. It waits
 * in the queue until then, and joins the line at that time: `api:admin:start-scheduled` sleeps
 * until it's due and starts it, or it waits for the job that is running then.
 *
 * @phpstan-type Job array{id: string, label: string, args: list<string>, queuedAt?: string, runAt?: ?string, startedAt: ?string, finishedAt: ?string, exitCode: ?int, pid: ?int, stoppable?: bool, stopped?: bool}
 */
final readonly class AdminJobService
{
    /** How many finished jobs are kept; older ones are removed when a new one is added. */
    private const int KEEP = 20;

    /** Image options of `api:sync`, as the admin offers them. */
    public const array IMAGE_MODES = [
        'new' => 'New images only',
        'postpone' => 'Queue new images, download later',
        'skip' => 'No images',
        'all' => 'All images again',
    ];

    /** Default time of day for a scheduled job, in {@see self::timezone()}: quiet hours. */
    public const string DEFAULT_SCHEDULE_TIME = '04:00';

    private string $dir;

    public function __construct(
        #[Autowire('%kernel.project_dir%')]
        private string $projectDir,
        #[Autowire(env: 'ADMIN_TIMEZONE')]
        private string $timezoneName = 'Europe/Amsterdam',
    ) {
        $this->dir = $projectDir . '/var/admin-jobs';
    }

    /**
     * The time zone the admin enters and shows times in (env ADMIN_TIMEZONE); the server runs in UTC.
     */
    public function timezone(): DateTimeZone
    {
        return new DateTimeZone($this->timezoneName);
    }

    /**
     * The next {@see self::DEFAULT_SCHEDULE_TIME}: today if it's still to come, otherwise tomorrow.
     */
    public function defaultRunAt(): DateTimeImmutable
    {
        $now = new DateTimeImmutable('now', $this->timezone());
        [$hour, $minute] = array_map(intval(...), explode(':', self::DEFAULT_SCHEDULE_TIME));
        $today = $now->setTime($hour, $minute);

        return $today > $now ? $today : $today->modify('+1 day');
    }

    /**
     * The commands to run from cron on the server, as crontab lines, with the admin action that
     * runs the same now (null when there's no point: the admin already does it on every visit).
     *
     * @var list<array{schedule: string, command: string, does: string, action: ?string}>
     */
    public const array CRON_JOBS = [
        ['schedule' => '30 3 * * *', 'command' => 'api:cleanup', 'does' => 'Deletes expired sync codes and old change ids, daily.', 'action' => 'cleanup'],
        ['schedule' => '*/5 * * * *', 'command' => 'api:notifications', 'does' => 'Wishlist notifications: builds the day\'s pushes after NOTIFY_BUILD_AT and sends them between NOTIFY_SEND_FROM and NOTIFY_SEND_UNTIL (ADMIN_TIMEZONE). Does nothing otherwise.', 'action' => null],
        ['schedule' => '* * * * *', 'command' => 'api:admin:start-scheduled --due', 'does' => 'Starts scheduled jobs that are due, should their waiter have died (e.g. a restart). Visiting this page does the same.', 'action' => null],
    ];

    /**
     * The command line for an action from the admin form. Throws for anything that isn't one.
     *
     * @return array{label: string, args: list<string>}
     */
    public function action(string $action, string $game, string $imageMode = 'new'): array
    {
        if ($action === 'cleanup') { // For every game
            return ['label' => 'Clean up (expired sync codes, old change ids)', 'args' => ['api:cleanup']];
        }

        $gameCase = Game::tryFrom($game) ?? throw new InvalidArgumentException(sprintf('Unknown game "%s".', $game));

        return match ($action) {
            'sync' => [
                'label' => sprintf('Sync %s (%s)', $gameCase->value, strtolower(self::IMAGE_MODES[$imageMode] ?? throw new InvalidArgumentException('Unknown image mode.'))),
                'args' => ['api:sync', $gameCase->value, ...match ($imageMode) {
                    'postpone' => ['--postpone-images'],
                    'skip' => ['--skip-images'],
                    'all' => ['--all-images'],
                    default => [],
                }],
            ],
            'images' => [
                'label' => sprintf('Process queued images of %s', $gameCase->value),
                'args' => ['api:process-images', $gameCase->value],
            ],
            default => throw new InvalidArgumentException(sprintf('Unknown action "%s".', $action)),
        };
    }

    /**
     * Adds a job to the queue, and starts it right away when nothing else runs. With $runAt, it
     * waits until then instead (once; it doesn't repeat).
     *
     * @param list<string> $args the console command and its arguments
     *
     * @return Job
     */
    public function enqueue(string $label, array $args, ?DateTimeImmutable $runAt = null): array
    {
        if ($runAt !== null && $runAt <= new DateTimeImmutable()) {
            throw new InvalidArgumentException('Pick a time in the future.');
        }

        $this->prune();
        if (!is_dir($this->dir) && !mkdir($this->dir, 0775, true) && !is_dir($this->dir)) {
            throw new RuntimeException(sprintf('Could not create %s.', $this->dir));
        }

        $job = [
            'id' => Uuid::v7()->toRfc4122(),
            'label' => $label,
            'args' => $args,
            'queuedAt' => new DateTimeImmutable()->format(DATE_ATOM),
            'runAt' => $runAt?->format(DATE_ATOM),
            'startedAt' => null,
            'finishedAt' => null,
            'exitCode' => null,
            'pid' => null,
        ];
        $this->save($job);
        file_put_contents($this->logPath($job['id']), '');

        if ($runAt !== null) {
            $this->launch(['api:admin:start-scheduled', $job['id']]); // Starts it when it's due
        }
        $this->startNext();

        return $this->find($job['id']) ?? $job;
    }

    /**
     * Starts the first queued job that is due, unless one is running. Locked, so two requests (or
     * a request and a runner) never start two jobs at once.
     */
    public function startNext(): void
    {
        if (!is_dir($this->dir)) {
            return;
        }

        $lock = fopen($this->dir . '/queue.lock', 'c');
        if ($lock === false || !flock($lock, LOCK_EX)) {
            return;
        }

        try {
            $next = array_values(array_filter($this->queued(), $this->isDue(...)))[0] ?? null;
            if ($next === null || $this->running() !== null) {
                return;
            }

            $next['startedAt'] = new DateTimeImmutable()->format(DATE_ATOM);
            $this->save($next);
            $this->launch(['api:admin:run-job', $next['id']]);
        } finally {
            flock($lock, LOCK_UN);
            fclose($lock);
        }
    }

    /**
     * Removes a job that is still waiting in the queue. False when it isn't waiting (anymore).
     */
    public function cancel(string $id): bool
    {
        $job = $this->find($id);
        if ($job === null || !$this->isQueued($job)) {
            return false;
        }

        @unlink($this->metaPath($id));
        @unlink($this->logPath($id));

        return true;
    }

    /**
     * Asks the runner of a running job to stop it; it checks every half second. False when the job
     * isn't running, or its runner can't be stopped this way (started before stopping existed).
     */
    public function requestStop(string $id): bool
    {
        $job = $this->find($id);
        if ($job === null || !$this->isRunning($job) || !($job['stoppable'] ?? false)) {
            return false;
        }

        return touch($this->stopPath($id));
    }

    public function isStopRequested(string $id): bool
    {
        return is_file($this->stopPath($id));
    }

    public function clearStopRequest(string $id): void
    {
        @unlink($this->stopPath($id));
    }

    /**
     * Starts a console command ($command: its name and arguments) detached from this request.
     * Outside the job queue: also for short things such as sending announcements now.
     *
     * @param list<string> $command
     */
    public function launch(array $command): void
    {
        $php = new PhpExecutableFinder()->find() ?: 'php';
        $runner = [$php, $this->projectDir . '/bin/console', ...$command];

        if (DIRECTORY_SEPARATOR === '\\') {
            // Windows (development): Start-Process detaches it from this request, without a window.
            // Sent encoded, so no quoting has to survive cmd.
            $quote = static fn (string $value): string => "'" . str_replace("'", "''", $value) . "'";
            $script = sprintf(
                'Start-Process -WindowStyle Hidden -FilePath %s -ArgumentList %s -WorkingDirectory %s',
                $quote($runner[0]),
                implode(',', array_map(static fn (string $arg): string => $quote('"' . $arg . '"'), array_slice($runner, 1))),
                $quote($this->projectDir),
            );
            $encoded = base64_encode(mb_convert_encoding($script, 'UTF-16LE', 'UTF-8'));
            new Process(['powershell', '-NoProfile', '-NonInteractive', '-EncodedCommand', $encoded], $this->projectDir)->run();
        } else {
            // The shell puts it in the background and exits right away; nohup keeps it alive
            $command = 'nohup ' . implode(' ', array_map(escapeshellarg(...), $runner)) . ' > /dev/null 2>&1 &';
            Process::fromShellCommandline($command, $this->projectDir)->run();
        }
    }

    /**
     * @return ?Job
     */
    public function find(string $id): ?array
    {
        if (!Uuid::isValid($id) || !is_file($this->metaPath($id))) {
            return null;
        }

        /** @var Job */
        return json_decode((string) file_get_contents($this->metaPath($id)), true, flags: JSON_THROW_ON_ERROR);
    }

    /**
     * Jobs, newest first (by when they were added).
     *
     * @return list<Job>
     */
    public function all(): array
    {
        $jobs = [];
        foreach (glob($this->dir . '/*.json') ?: [] as $file) {
            $job = $this->find(basename($file, '.json'));
            if ($job !== null) {
                $jobs[] = $job;
            }
        }
        // Ids (UUIDv7) are in creation order too, for jobs added within the same second
        usort($jobs, static fn (array $a, array $b): int => [self::addedAt($b), $b['id']] <=> [self::addedAt($a), $a['id']]);

        return $jobs;
    }

    /**
     * Jobs waiting to start, next first: in the order they join the line, which for a scheduled
     * job is its time.
     *
     * @return list<Job>
     */
    public function queued(): array
    {
        $queued = array_values(array_filter($this->all(), $this->isQueued(...)));
        usort($queued, static fn (array $a, array $b): int
            => [new DateTimeImmutable(self::inLineAt($a)), $a['id']] <=> [new DateTimeImmutable(self::inLineAt($b)), $b['id']]);

        return $queued;
    }

    /**
     * @param Job $job
     */
    public function isQueued(array $job): bool
    {
        return $job['startedAt'] === null;
    }

    /**
     * Not scheduled, or its time has come.
     *
     * @param Job $job
     */
    public function isDue(array $job): bool
    {
        return ($job['runAt'] ?? null) === null || new DateTimeImmutable($job['runAt']) <= new DateTimeImmutable();
    }

    /**
     * The job that is still running, if any.
     *
     * @return ?Job
     */
    public function running(): ?array
    {
        foreach ($this->all() as $job) {
            if ($this->isRunning($job)) {
                return $job;
            }
        }

        return null;
    }

    /**
     * Not finished, and its runner is still alive (or hasn't had time to report its pid yet).
     *
     * @param Job $job
     */
    public function isRunning(array $job): bool
    {
        if ($job['startedAt'] === null || $job['exitCode'] !== null) {
            return false;
        }
        if ($job['pid'] === null) {
            return new DateTimeImmutable($job['startedAt']) > new DateTimeImmutable('-30 seconds');
        }
        if (function_exists('posix_kill')) {
            return posix_kill($job['pid'], 0);
        }
        if (DIRECTORY_SEPARATOR === '\\') {
            // Windows (development): no posix, ask tasklist. It prints the process when it exists.
            $tasklist = new Process(['tasklist', '/FI', sprintf('PID eq %d', $job['pid']), '/NH']);
            $tasklist->run();

            return !$tasklist->isSuccessful() || preg_match(sprintf('/\b%d\b/', $job['pid']), $tasklist->getOutput()) === 1;
        }

        return true; // No way to check: trust the job file
    }

    /**
     * The job's output from byte $offset on, and the offset to ask for next.
     *
     * @return array{output: string, offset: int}
     */
    public function readLog(string $id, int $offset): array
    {
        $path = $this->logPath($id);
        $size = is_file($path) ? (int) filesize($path) : 0;
        if ($offset >= $size) {
            return ['output' => '', 'offset' => $size];
        }

        $output = (string) file_get_contents($path, false, null, $offset);

        return ['output' => $output, 'offset' => $offset + strlen($output)];
    }

    /**
     * @param Job $job
     */
    public function save(array $job): void
    {
        file_put_contents($this->metaPath($job['id']), json_encode($job, JSON_THROW_ON_ERROR | JSON_PRETTY_PRINT), LOCK_EX);
    }

    public function logPath(string $id): string
    {
        return sprintf('%s/%s.log', $this->dir, $id);
    }

    private function stopPath(string $id): string
    {
        return sprintf('%s/%s.stop', $this->dir, $id);
    }

    private function metaPath(string $id): string
    {
        return sprintf('%s/%s.json', $this->dir, $id);
    }

    /**
     * When the job was added: jobs from before the queue only have `startedAt`.
     *
     * @param Job $job
     */
    private static function addedAt(array $job): string
    {
        return $job['queuedAt'] ?? $job['startedAt'] ?? '';
    }

    /**
     * When the job joins the line to run: its scheduled time, or when it was added.
     *
     * @param Job $job
     */
    private static function inLineAt(array $job): string
    {
        return $job['runAt'] ?? self::addedAt($job);
    }

    /** Removes the oldest finished jobs past {@see self::KEEP}; queued and running ones stay. */
    private function prune(): void
    {
        $done = array_filter($this->all(), fn (array $job): bool => !$this->isQueued($job) && !$this->isRunning($job));
        foreach (array_slice(array_values($done), self::KEEP - 1) as $job) {
            @unlink($this->metaPath($job['id']));
            @unlink($this->logPath($job['id']));
        }
    }
}
