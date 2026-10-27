<?php declare(strict_types=1);

namespace App\Command;

use App\Repository\AppliedChangeRepository;
use App\Repository\SyncCodeRepository;
use DateTimeImmutable;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

use function sprintf;

/**
 * Housekeeping, for cron (daily) or from the admin's Sync page: deletes sync codes that expired or
 * were used, and the ids of applied app changes once no app retries them any more.
 */
#[AsCommand(name: 'api:cleanup', description: 'Delete expired sync codes and old applied change ids. For cron, daily.')]
final class CleanupCommand extends Command
{
    /** How long an app may retry a change; its id is kept that long, so a retry counts once. */
    private const string KEEP_CHANGES_FOR = '-30 days';

    public function __construct(
        private readonly SyncCodeRepository $syncCodes,
        private readonly AppliedChangeRepository $appliedChanges,
    ) {
        parent::__construct();
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $output->writeln(sprintf('Deleted %d expired or used sync codes.', $this->syncCodes->deleteExpired()));
        $output->writeln(sprintf(
            'Deleted %d applied change ids older than 30 days.',
            $this->appliedChanges->deleteOlderThan(new DateTimeImmutable(self::KEEP_CHANGES_FOR)),
        ));

        return Command::SUCCESS;
    }
}
