<?php declare(strict_types=1);

namespace App\Entity;

use App\ApiResource\Traits\TimestampableTrait;
use App\Enum\CardListType;
use App\Enum\Game;
use App\Repository\AnnouncementRepository;
use DateTimeImmutable;
use Doctrine\ORM\Mapping as ORM;

use function array_filter;
use function array_map;
use function array_values;

/**
 * A notification written in the admin (an event, a new set, an offer), sent at {@see self::$sendAt}
 * to every device with the "News and events" switch on, or only those of collectors of some games:
 * users with cards of {@see self::$games} in a collection and/or wishlist ({@see self::$lists}).
 * Sent by `api:notifications` (cron) once due, see {@see \App\Service\AnnouncementSender}.
 */
#[ORM\Entity(repositoryClass: AnnouncementRepository::class)]
#[ORM\Table(name: 'announcement')]
#[ORM\Index(name: 'idx_announcement_status_send_at', columns: ['status', 'send_at'])]
#[ORM\HasLifecycleCallbacks]
class Announcement
{
    use TimestampableTrait;

    public const string SCHEDULED = 'scheduled';
    public const string SENDING = 'sending';
    public const string SENT = 'sent';
    public const string CANCELLED = 'cancelled';
    public const string FAILED = 'failed';

    /** Pages a tap can open, as the app's routes, with their names in the admin. */
    public const array ROUTES = ['' => 'Just open the app', '/catalog' => 'Catalog', '/collection' => 'Collection', '/wishlist' => 'Wishlist'];

    public const int MAX_TITLE = 100;
    public const int MAX_BODY = 500;

    #[ORM\Id]
    #[ORM\Column]
    #[ORM\GeneratedValue]
    public private(set) int $id;

    #[ORM\Column(length: self::MAX_TITLE)]
    public string $title;

    #[ORM\Column(length: self::MAX_BODY)]
    public string $body;

    /**
     * Only collectors of these games (values of {@see Game}); empty: everyone.
     *
     * @var list<string>
     */
    #[ORM\Column(type: 'json')]
    public array $games = [];

    /**
     * Where they must have those cards: in a collection, a wishlist, or either (both listed).
     *
     * @var list<string>
     */
    #[ORM\Column(type: 'json')]
    public array $lists = [CardListType::Collection->value, CardListType::Wishlist->value];

    /** The page a tap opens, or null for just the app. */
    #[ORM\Column(length: 40, nullable: true)]
    public ?string $route = null;

    #[ORM\Column]
    public DateTimeImmutable $sendAt;

    #[ORM\Column(length: 20)]
    public private(set) string $status = self::SCHEDULED;

    #[ORM\Column(length: 180)]
    public private(set) string $createdBy;

    #[ORM\Column(nullable: true)]
    public private(set) ?DateTimeImmutable $sentAt = null;

    /** Devices it went to. */
    #[ORM\Column]
    public private(set) int $devices = 0;

    /** Devices it couldn't be sent to (not counting ones Firebase no longer knows). */
    #[ORM\Column]
    public private(set) int $failures = 0;

    #[ORM\Column(length: 255, nullable: true)]
    public private(set) ?string $error = null;

    public function __construct(string $title, string $body, DateTimeImmutable $sendAt, string $createdBy)
    {
        $this->title = $title;
        $this->body = $body;
        $this->sendAt = $sendAt;
        $this->createdBy = $createdBy;
        $this->initializeTimestamps();
    }

    public function isScheduled(): bool
    {
        return $this->status === self::SCHEDULED;
    }

    public function isForEveryone(): bool
    {
        return $this->games === [];
    }

    /** @return list<Game> */
    public function gameCases(): array
    {
        return array_values(array_filter(array_map(Game::tryFrom(...), $this->games)));
    }

    /** @return list<CardListType> */
    public function listTypes(): array
    {
        return array_values(array_filter(array_map(CardListType::tryFrom(...), $this->lists)));
    }

    public function cancel(): void
    {
        $this->status = self::CANCELLED;
    }

    public function markSending(): void
    {
        $this->status = self::SENDING;
    }

    public function markSent(int $devices, int $failures): void
    {
        $this->status = self::SENT;
        $this->sentAt = new DateTimeImmutable();
        $this->devices = $devices;
        $this->failures = $failures;
    }

    public function markFailed(string $error): void
    {
        $this->status = self::FAILED;
        $this->error = mb_substr($error, 0, 255);
    }
}
