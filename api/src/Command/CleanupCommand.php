<?php declare(strict_types=1);

namespace App\Command;

use App\Repository\AppliedChangeRepository;
use App\Repository\DeviceNotificationRepository;
use App\Repository\SyncCodeRepository;
use App\Repository\WishlistPushRepository;
use DateTimeImmutable;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

use function sprintf;

/**
 * Housekeeping, for cron (daily) or from the admin's Sync page: deletes sync codes that expired or
 * were used, the ids of applied app changes once no app retries them any more, and old wishlist
 * notifications.
 */
#[AsCommand(name: 'api:cleanup', description: 'Delete expired sync codes, old applied change ids and old wishlist notifications. For cron, daily.')]
final class CleanupCommand extends Command
{
    /** How long an app may retry a change; its id is kept that long, so a retry counts once. */
    private const string KEEP_CHANGES_FOR = '-30 days';

    /** Built wishlist notifications, sent or not, with their notices. */
    private const string KEEP_PUSHES_FOR = '-30 days';

    /** The app's list of received notifications. */
    private const string KEEP_RECEIVED_FOR = '-90 days';

    public function __construct(
        private readonly DeviceNotificationRepository $received,
        private readonly SyncCodeRepository $syncCodes,
        private readonly AppliedChangeRepository $appliedChanges,
        private readonly WishlistPushRepository $wishlistPushes,
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
        $output->writeln(sprintf(
            'Deleted %d wishlist notifications older than 30 days.',
            $this->wishlistPushes->deleteOlderThan(new DateTimeImmutable(self::KEEP_PUSHES_FOR)),
        ));
        $output->writeln(sprintf(
            'Deleted %d received notifications older than 90 days (the app\'s list).',
            $this->received->deleteOlderThan(new DateTimeImmutable(self::KEEP_RECEIVED_FOR)),
        ));

        return Command::SUCCESS;
    }
}
