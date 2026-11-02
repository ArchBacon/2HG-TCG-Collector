<?php declare(strict_types=1);

namespace App\Service;

use App\Entity\User;
use App\Entity\WishlistNotice;
use App\Entity\WishlistPush;
use App\Enum\Game;
use App\Entity\DeviceNotification;
use App\Repository\DeviceNotificationRepository;
use App\Repository\DeviceTokenRepository;
use App\Repository\SettingRepository;
use App\Repository\WishlistNoticeRepository;
use App\Repository\WishlistPushRepository;
use DateTimeImmutable;
use DateTimeZone;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\Uid\Uuid;

use function array_slice;
use function array_unique;
use function array_values;
use function count;
use function implode;
use function sprintf;

/**
 * Wishlist notifications: "a card on your wishlist is in stock".
 *
 * 1. Record: when stock comes in, {@see self::recordInStock()} adds a pending
 *    {@see WishlistNotice} for every user with the card on a wishlist. Nothing is sent yet.
 * 2. Build: once a day at env NOTIFY_BUILD_AT (00:00), {@see self::build()} turns each user's
 *    pending notices into one {@see WishlistPush}.
 * 3. Send: between NOTIFY_SEND_FROM and NOTIFY_SEND_UNTIL (08:00 to 20:00), {@see self::send()}
 *    sends the built pushes to the user's devices that have the switch on.
 *
 * All times are in env ADMIN_TIMEZONE (Europe/Amsterdam); the server runs in UTC.
 * `api:notifications` runs the build and send when they're due, from cron every few minutes.
 */
final readonly class WishlistNotifier
{
    /** When the last build ran (its day, Y-m-d), in app_setting. */
    private const string LAST_BUILD_SETTING = 'notifications.last_build';

    /** Pushes sent per batch; a run keeps going while the window is open. */
    private const int SEND_BATCH = 100;

    /** Card names in a push's text; the rest are counted ("and 2 more"). */
    private const int NAMES_SHOWN = 3;

    public const string ROUTE = '/wishlist';

    public function __construct(
        private WishlistNoticeRepository $notices,
        private WishlistPushRepository $pushes,
        private DeviceTokenRepository $devices,
        private DeviceNotificationRepository $received,
        private SettingRepository $settings,
        private UserCardService $cards,
        private FcmClient $fcm,
        private EntityManagerInterface $entityManager,
        #[Autowire(env: 'ADMIN_TIMEZONE')]
        private string $timezoneName,
        #[Autowire(env: 'NOTIFY_BUILD_AT')]
        private string $buildAt,
        #[Autowire(env: 'NOTIFY_SEND_FROM')]
        private string $sendFrom,
        #[Autowire(env: 'NOTIFY_SEND_UNTIL')]
        private string $sendUntil,
    ) {}

    public function timezone(): DateTimeZone
    {
        return new DateTimeZone($this->timezoneName);
    }

    public function now(): DateTimeImmutable
    {
        return new DateTimeImmutable('now', $this->timezone());
    }

    /**
     * Records pending notices for the cards of $game that came into stock. Returns how many.
     *
     * @param list<Uuid> $cardIds
     */
    public function recordInStock(Game $game, array $cardIds): int
    {
        $unique = [];
        foreach ($cardIds as $id) {
            $unique[$id->toRfc4122()] = $id;
        }

        return $this->notices->recordInStock($game, array_values($unique), $this->now()->setTime(0, 0));
    }

    /**
     * Whether today's build is due: past the build time, and not built yet today.
     */
    public function isBuildDue(?DateTimeImmutable $now = null): bool
    {
        $now ??= $this->now();

        return $now >= $this->at($now, $this->buildAt)
            && $this->settings->find(self::LAST_BUILD_SETTING)?->value !== $now->format('Y-m-d');
    }

    /**
     * Whether pushes may be sent now: within the send window.
     */
    public function isSendWindowOpen(?DateTimeImmutable $now = null): bool
    {
        $now ??= $this->now();

        return $now >= $this->at($now, $this->sendFrom) && $now < $this->at($now, $this->sendUntil);
    }

    /**
     * Turns each user's pending notices into one push. Notices of users without a device that
     * wants them are dropped, as are those of cards no longer in the catalog.
     *
     * @return array{pushes: int, notices: int, dropped: int}
     */
    public function build(): array
    {
        $result = ['pushes' => 0, 'notices' => 0, 'dropped' => 0];

        /** @var array<string, array{user: User, notices: list<WishlistNotice>}> $byUser */
        $byUser = [];
        /** @var array<string, list<Uuid>> $idsByGame */
        $idsByGame = [];
        foreach ($this->notices->findPending() as $notice) {
            $key = $notice->user->id->toRfc4122();
            $byUser[$key] ??= ['user' => $notice->user, 'notices' => []];
            $byUser[$key]['notices'][] = $notice;
            $idsByGame[$notice->game][] = $notice->cardId;
        }

        $names = []; // "game:id" => name
        foreach ($idsByGame as $game => $ids) {
            $gameCase = Game::tryFrom($game);
            foreach ($gameCase === null ? [] : $this->cards->findCards($gameCase, $ids) as $id => $card) {
                $names["$game:$id"] = $card->name;
            }
        }

        foreach ($byUser as ['user' => $user, 'notices' => $notices]) {
            $cardNames = [];
            $kept = [];
            foreach ($notices as $notice) {
                $name = $names[$notice->game . ':' . $notice->cardId->toRfc4122()] ?? null;
                if ($name === null) {
                    $this->entityManager->remove($notice);
                    $result['dropped']++;
                    continue;
                }
                $cardNames[] = $name;
                $kept[] = $notice;
            }

            if ($kept === []) {
                continue;
            }
            if ($this->devices->findWantingWishlist($user) === []) {
                foreach ($kept as $notice) {
                    $this->entityManager->remove($notice);
                }
                $result['dropped'] += count($kept);
                continue;
            }

            [$title, $body] = self::text(array_values(array_unique($cardNames)));
            $push = new WishlistPush($user, $title, $body, count($kept));
            $this->entityManager->persist($push);
            foreach ($kept as $notice) {
                $notice->push = $push;
            }
            $result['pushes']++;
            $result['notices'] += count($kept);
        }

        $this->entityManager->flush();
        $this->settings->set(self::LAST_BUILD_SETTING, $this->now()->format('Y-m-d'));

        return $result;
    }

    /**
     * Sends the built pushes, in batches, while $keepGoing says so (e.g. the window is open).
     * Tokens Firebase calls invalid are deleted. Doesn't check the window itself.
     *
     * @param callable(): bool $keepGoing
     *
     * @return array{pushes: int, devices: int, failed: int, invalidTokens: int}
     */
    public function send(callable $keepGoing): array
    {
        $result = ['pushes' => 0, 'devices' => 0, 'failed' => 0, 'invalidTokens' => 0];

        $afterId = 0; // Each push once per run: one that failed waits for the next run
        while ($keepGoing()) {
            $batch = $this->pushes->findUnsent(self::SEND_BATCH, $afterId);
            if ($batch === []) {
                break;
            }

            foreach ($batch as $push) {
                $this->sendPush($push, $result);
                $afterId = $push->id;
            }
            $this->entityManager->flush();
            $this->entityManager->clear();
        }

        return $result;
    }

    /**
     * Sends a test notification to all of a user's devices, whatever their switch and the window.
     *
     * @return list<array{token: string, result: FcmResult}>
     */
    public function sendTest(User $user): array
    {
        [$title, $body] = ['Test notification', 'Notifications from 2HG TCG Collector work on this device.'];

        $results = [];
        foreach ($this->devices->findBy(['user' => $user]) as $device) {
            $result = $this->fcm->send($device->token, $title, $body, ['type' => 'test', 'route' => self::ROUTE]);
            if ($result->sent) {
                $this->received->record([$device->id], DeviceNotification::TEST, $title, $body, self::ROUTE);
            }
            $results[] = ['token' => $device->token, 'result' => $result];
        }

        return $results;
    }

    /**
     * @param array{pushes: int, devices: int, failed: int, invalidTokens: int} $result
     */
    private function sendPush(WishlistPush $push, array &$result): void
    {
        $devices = $this->devices->findWantingWishlist($push->user);
        if ($devices === []) {
            $push->giveUp('No device wants wishlist notifications any more.');
            return;
        }

        $sent = 0;
        $sentTo = [];
        $error = null;
        foreach ($devices as $device) {
            $sendResult = $this->fcm->send($device->token, $push->title, $push->body, [
                'type' => 'wishlist_in_store',
                'route' => self::ROUTE,
            ]);
            if ($sendResult->sent) {
                $sent++;
                $sentTo[] = $device->id;
            } elseif ($sendResult->invalidToken) {
                $this->entityManager->remove($device);
                $result['invalidTokens']++;
            } else {
                $error = $sendResult->error;
            }
        }

        // For the app's list of received notifications
        $this->received->record($sentTo, DeviceNotification::WISHLIST, $push->title, $push->body, self::ROUTE);

        // Sent to at least one device: done, so the others don't get it twice on a retry
        if ($sent > 0) {
            $push->markSent();
            $result['pushes']++;
            $result['devices'] += $sent;
        } elseif ($error !== null) {
            $push->markAttemptFailed($error);
            $result['failed']++;
        } else {
            $push->giveUp('All of its devices had invalid tokens.');
        }
    }

    /**
     * $time ("HH:MM") on $now's day.
     */
    private function at(DateTimeImmutable $now, string $time): DateTimeImmutable
    {
        [$hour, $minute] = array_map(intval(...), explode(':', $time) + [1 => '0']);

        return $now->setTime($hour, $minute);
    }

    /**
     * The push's title and body for these card names.
     *
     * @param list<string> $names
     *
     * @return array{string, string}
     */
    private static function text(array $names): array
    {
        if (count($names) === 1) {
            return [sprintf('%s is in stock', $names[0]), 'A card from your wishlist is now for sale at 2HG.'];
        }

        $shown = array_slice($names, 0, self::NAMES_SHOWN);
        $more = count($names) - count($shown);
        $list = $more > 0
            ? implode(', ', $shown) . sprintf(' and %d more', $more)
            : implode(', ', array_slice($shown, 0, -1)) . ' and ' . $shown[count($shown) - 1];

        return [sprintf('%d cards from your wishlist are in stock', count($names)), "$list are now for sale at 2HG."];
    }
}
