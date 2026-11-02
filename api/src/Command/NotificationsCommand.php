<?php declare(strict_types=1);

namespace App\Command;

use App\Entity\DeviceToken;
use App\Entity\User;
use App\Enum\Game;
use App\Service\AnnouncementSender;
use App\Service\FcmClient;
use App\Service\WishlistNotifier;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\Uid\Uuid;
use Doctrine\ORM\EntityManagerInterface;

use function explode;
use function fclose;
use function flock;
use function fopen;
use function is_string;
use function sprintf;

/**
 * Notifications, for cron every 5 minutes. Sends the admin's announcements that are due
 * ({@see AnnouncementSender}). Wishlist notifications ({@see WishlistNotifier}): builds the day's
 * pushes once the build time has passed, and sends built pushes while the send window is open.
 * Does nothing otherwise, so it can run as often as wanted. Runs never overlap (a lock file).
 *
 * For testing: --build and --send do that now whatever the time; --in-stock only records a card
 * as having come into stock, and --test only sends a test notification to a user's devices.
 */
#[AsCommand(name: 'api:notifications', description: 'Build and send wishlist notifications when due. For cron, every 5 minutes.')]
final class NotificationsCommand extends Command
{
    public function __construct(
        private readonly WishlistNotifier $notifier,
        private readonly AnnouncementSender $announcements,
        private readonly FcmClient $fcm,
        private readonly EntityManagerInterface $entityManager,
        #[Autowire('%kernel.project_dir%/var/notifications.lock')]
        private readonly string $lockFile,
    ) {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this
            ->addOption('build', null, InputOption::VALUE_NONE, 'Build the pushes now, whatever the time')
            ->addOption('send', null, InputOption::VALUE_NONE, 'Send the built pushes now, outside the window too')
            ->addOption('in-stock', null, InputOption::VALUE_REQUIRED, 'Record a card as come into stock: <game>:<card id>')
            ->addOption('announcements', null, InputOption::VALUE_NONE, 'Only send the admin\'s announcements that are due (what "Send now" runs)')
            ->addOption('test', null, InputOption::VALUE_REQUIRED, 'Send a test notification to the devices of this user id, or "latest": the user of the device registered last');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        // Announcements only (the admin's "Send now"): no lock needed, each is claimed before sending
        if ($input->getOption('announcements')) {
            return $this->sendAnnouncements($output);
        }

        $lock = fopen($this->lockFile, 'c');
        if ($lock === false || !flock($lock, LOCK_EX | LOCK_NB)) {
            $output->writeln('Another run is busy; skipping.');
            return Command::SUCCESS;
        }

        try {
            return $this->handle($input, $output);
        } finally {
            flock($lock, LOCK_UN);
            fclose($lock);
        }
    }

    private function handle(InputInterface $input, OutputInterface $output): int
    {
        $inStock = $input->getOption('in-stock');
        if (is_string($inStock)) {
            [$game, $cardId] = explode(':', $inStock, 2) + [1 => ''];
            $gameCase = Game::tryFrom($game);
            if ($gameCase === null || !Uuid::isValid($cardId)) {
                $output->writeln('<error>--in-stock takes <game>:<card id>, e.g. pokemon:0190...</error>');
                return Command::INVALID;
            }
            $output->writeln(sprintf('Recorded %d notices.', $this->notifier->recordInStock($gameCase, [Uuid::fromString($cardId)])));

            return Command::SUCCESS; // Only that: building and sending wait for their time (or --build, --send)
        }

        $test = $input->getOption('test');
        if (is_string($test)) {
            return $this->sendTest($test, $output);
        }

        // The admin's announcements, at the time set for them (no send window: the admin picked it)
        $this->sendAnnouncements($output);

        $now = $this->notifier->now();
        if ($input->getOption('build') || $this->notifier->isBuildDue($now)) {
            $built = $this->notifier->build();
            $output->writeln(sprintf(
                'Built %d pushes from %d notices; dropped %d (no device wants them, or the card is gone).',
                $built['pushes'],
                $built['notices'],
                $built['dropped'],
            ));
        }

        $force = (bool) $input->getOption('send');
        if (!$force && !$this->notifier->isSendWindowOpen($now)) {
            return Command::SUCCESS;
        }
        if (!$this->fcm->isConfigured()) {
            $output->writeln('<comment>Firebase is not set up (FIREBASE_CREDENTIALS); not sending.</comment>');
            return Command::SUCCESS;
        }

        $sent = $this->notifier->send(fn (): bool => $force || $this->notifier->isSendWindowOpen());
        $output->writeln(sprintf(
            'Sent %d pushes to %d devices; %d failed (retried next run), %d invalid tokens removed.',
            $sent['pushes'],
            $sent['devices'],
            $sent['failed'],
            $sent['invalidTokens'],
        ));

        return Command::SUCCESS;
    }

    private function sendAnnouncements(OutputInterface $output): int
    {
        if (!$this->fcm->isConfigured()) {
            return Command::SUCCESS; // They stay scheduled; the wishlist part says Firebase isn't set up
        }

        foreach ($this->announcements->sendDue() as $sent) {
            $output->writeln($sent['error'] === null
                ? sprintf('Announcement "%s": sent to %d devices, %d failed.', $sent['title'], $sent['devices'], $sent['failures'])
                : sprintf('<error>Announcement "%s" failed: %s</error>', $sent['title'], $sent['error']));
        }

        return Command::SUCCESS;
    }

    private function sendTest(string $userId, OutputInterface $output): int
    {
        $user = match (true) {
            // The user of the device that registered last, e.g. the phone just started for a test
            $userId === 'latest' => $this->entityManager->getRepository(DeviceToken::class)->findOneBy([], ['updatedAt' => 'DESC'])?->user,
            Uuid::isValid($userId) => $this->entityManager->find(User::class, Uuid::fromString($userId)),
            default => null,
        };
        if ($user === null) {
            $output->writeln("<error>No user with id $userId.</error>");
            return Command::FAILURE;
        }
        if (!$this->fcm->isConfigured()) {
            $output->writeln('<error>Firebase is not set up (FIREBASE_CREDENTIALS).</error>');
            return Command::FAILURE;
        }

        $results = $this->notifier->sendTest($user);
        if ($results === []) {
            $output->writeln('That user has no registered devices.');
        }
        foreach ($results as ['token' => $token, 'result' => $result]) {
            $output->writeln(sprintf('%s…: %s', substr($token, 0, 16), $result->sent ? 'sent' : ($result->error ?? 'failed')));
        }

        return Command::SUCCESS;
    }
}
