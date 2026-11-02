<?php declare(strict_types=1);

namespace App\Entity;

use App\Repository\WishlistPushRepository;
use DateTimeImmutable;
use Doctrine\ORM\Mapping as ORM;

/**
 * One push notification for a {@see User}, built from their pending {@see WishlistNotice}s (see
 * {@see \App\Service\WishlistNotifier::build()}) and sent later, within the send window, to each
 * of their devices that wants it.
 *
 * Unsent while {@see self::$sentAt} is null. A send that fails for another reason than invalid
 * tokens is retried on the next run, up to {@see self::MAX_ATTEMPTS}; after that it's given up
 * ({@see self::$failedAt}).
 */
#[ORM\Entity(repositoryClass: WishlistPushRepository::class)]
#[ORM\Table(name: 'wishlist_push')]
#[ORM\Index(name: 'idx_wishlist_push_sent_failed', columns: ['sent_at', 'failed_at'])]
class WishlistPush
{
    public const int MAX_ATTEMPTS = 5;

    #[ORM\Id]
    #[ORM\Column(type: 'bigint', unique: true)]
    #[ORM\GeneratedValue(strategy: 'AUTO')]
    public private(set) int $id;

    #[ORM\ManyToOne(targetEntity: User::class)]
    #[ORM\JoinColumn(name: 'user_id', referencedColumnName: 'id', nullable: false, onDelete: 'CASCADE')]
    public private(set) User $user;

    #[ORM\Column(type: 'string', length: 255)]
    public private(set) string $title;

    #[ORM\Column(type: 'string', length: 1000)]
    public private(set) string $body;

    /** How many cards it tells about. */
    #[ORM\Column]
    public private(set) int $cards;

    #[ORM\Column]
    public private(set) DateTimeImmutable $createdAt;

    #[ORM\Column(nullable: true)]
    public private(set) ?DateTimeImmutable $sentAt = null;

    #[ORM\Column(nullable: true)]
    public private(set) ?DateTimeImmutable $failedAt = null;

    #[ORM\Column]
    public private(set) int $attempts = 0;

    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public private(set) ?string $lastError = null;

    public function __construct(User $user, string $title, string $body, int $cards)
    {
        $this->user = $user;
        $this->title = $title;
        $this->body = $body;
        $this->cards = $cards;
        $this->createdAt = new DateTimeImmutable();
    }

    public function markSent(): void
    {
        $this->attempts++;
        $this->sentAt = new DateTimeImmutable();
        $this->lastError = null;
    }

    /**
     * Gives up without another try, e.g. when the user has no device that wants it any more.
     */
    public function giveUp(string $reason): void
    {
        $this->failedAt = new DateTimeImmutable();
        $this->lastError = mb_substr($reason, 0, 255);
    }

    /**
     * Records a failed attempt; gives up after {@see self::MAX_ATTEMPTS}.
     */
    public function markAttemptFailed(string $error): void
    {
        $this->attempts++;
        $this->lastError = mb_substr($error, 0, 255);
        if ($this->attempts >= self::MAX_ATTEMPTS) {
            $this->failedAt = new DateTimeImmutable();
        }
    }
}
