<?php declare(strict_types=1);

namespace App\Entity;

use App\Repository\WishlistNoticeRepository;
use DateTimeImmutable;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Uid\Uuid;

/**
 * A card on a user's wishlist that came into stock: recorded when the stock update (or a manual
 * link in the admin) takes it from 0 to more than 0. Nothing is sent right away; the notices of
 * a day are built into one {@see WishlistPush} per user (see {@see \App\Service\WishlistNotifier}).
 *
 * At most one per user, card and day ({@see self::$day}, in the notification time zone), whatever
 * the finish: the user hears about the card once even when several of its finishes come in.
 * Pending while {@see self::$push} is null.
 *
 * Rows are inserted in bulk by {@see WishlistNoticeRepository::recordInStock()}.
 */
#[ORM\Entity(repositoryClass: WishlistNoticeRepository::class)]
#[ORM\Table(name: 'wishlist_notice')]
#[ORM\UniqueConstraint(name: 'uniq_wishlist_notice_user_card_day', columns: ['user_id', 'game', 'card_id', 'notice_day'])]
#[ORM\Index(name: 'idx_wishlist_notice_push', columns: ['push_id'])]
class WishlistNotice
{
    #[ORM\Id]
    #[ORM\Column(type: 'bigint', unique: true)]
    #[ORM\GeneratedValue(strategy: 'AUTO')]
    public private(set) int $id;

    #[ORM\ManyToOne(targetEntity: User::class)]
    #[ORM\JoinColumn(name: 'user_id', referencedColumnName: 'id', nullable: false, onDelete: 'CASCADE')]
    public private(set) User $user;

    #[ORM\Column(type: 'string', length: 20)]
    public private(set) string $game;

    #[ORM\Column(type: 'uuid')]
    public private(set) Uuid $cardId;

    #[ORM\Column(name: 'notice_day', type: 'date_immutable')]
    public private(set) DateTimeImmutable $day;

    #[ORM\Column]
    public private(set) DateTimeImmutable $createdAt;

    #[ORM\ManyToOne(targetEntity: WishlistPush::class)]
    #[ORM\JoinColumn(name: 'push_id', referencedColumnName: 'id', nullable: true, onDelete: 'CASCADE')]
    public ?WishlistPush $push = null {
        get => $this->push;
        set => $this->push = $value;
    }

    private function __construct()
    {
        // Rows are inserted in bulk, see WishlistNoticeRepository::recordInStock()
    }
}
