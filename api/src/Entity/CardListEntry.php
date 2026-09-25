<?php declare(strict_types=1);

namespace App\Entity;

use App\ApiResource\Traits\TimestampableTrait;
use App\Repository\CardListEntryRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Uid\Uuid;

/**
 * How many copies of one card printing + finish are in a {@see CardList}. For a wishlist,
 * {@see self::$quantity} is the number of copies wanted.
 *
 * One row per (list, game, card, finish), enforced by the unique constraint: adding a card that
 * is already present bumps the quantity instead of adding a row, and a row whose quantity drops
 * to 0 is deleted. Quantity changes are applied as deltas (see
 * {@see CardListEntryRepository::applyDelta()}) so offline changes from several devices merge
 * instead of overwriting each other.
 *
 * Like {@see CardListing}, {@see self::$cardId} is a loose reference resolved per
 * {@see self::$game}, since each game has its own card table.
 */
#[ORM\Entity(repositoryClass: CardListEntryRepository::class)]
#[ORM\Table(name: 'card_list_entry')]
#[ORM\UniqueConstraint(name: 'uniq_card_list_entry_list_card_finish', columns: ['list_id', 'game', 'card_id', 'finish'])]
#[ORM\Index(name: 'idx_card_list_entry_game_card', columns: ['game', 'card_id'])]
#[ORM\HasLifecycleCallbacks]
class CardListEntry
{
    use TimestampableTrait;

    #[ORM\Id]
    #[ORM\Column(type: 'bigint', unique: true)]
    #[ORM\GeneratedValue(strategy: 'AUTO')]
    public private(set) int $id;

    #[ORM\ManyToOne(targetEntity: CardList::class, inversedBy: 'entries')]
    #[ORM\JoinColumn(name: 'list_id', referencedColumnName: 'id', nullable: false, onDelete: 'CASCADE')]
    public private(set) CardList $list;

    #[ORM\Column(type: 'string', length: 20)]
    public private(set) string $game;

    #[ORM\Column(type: 'uuid')]
    public private(set) Uuid $cardId;

    #[ORM\Column(type: 'string', length: 20)]
    public private(set) string $finish;

    #[ORM\Column(type: 'integer', options: ['unsigned' => true])]
    public int $quantity {
        get => $this->quantity;
        set {
            if ($value < 0) {
                throw new \InvalidArgumentException('Quantity cannot be negative.');
            }
            $this->quantity = $value;
        }
    }

    public function __construct(CardList $list, string $game, Uuid $cardId, string $finish, int $quantity)
    {
        $this->list = $list;
        $this->game = $game;
        $this->cardId = $cardId;
        $this->finish = $finish;
        $this->quantity = $quantity;
        $this->initializeTimestamps();
    }
}
