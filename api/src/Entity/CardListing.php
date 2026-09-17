<?php declare(strict_types=1);

namespace App\Entity;

use App\ApiResource\Traits\TimestampableTrait;
use App\Repository\CardListingRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Uid\Uuid;

/**
 * A shop listing (product id, stock, price) for one card printing + finish, matched against
 * a game's own Card table by an automatcher.
 *
 * Deliberately not game-specific and not FK-linked to any game's card table, the same as
 * {@see ImageJobQueue}: {@see self::$cardId} is a loose reference, resolved per
 * {@see self::$game}. `finish` is a plain string rather than an enum since the vocabulary is
 * per-game (MTG: nonfoil/foil/etched; other games will have their own).
 */
#[ORM\Entity(repositoryClass: CardListingRepository::class)]
#[ORM\Table(name: 'card_listing')]
#[ORM\UniqueConstraint(name: 'uniq_card_listing_game_card_finish', columns: ['game', 'card_id', 'finish'])]
#[ORM\UniqueConstraint(name: 'uniq_card_listing_game_product', columns: ['game', 'product_id'])]
#[ORM\HasLifecycleCallbacks]
class CardListing
{
    use TimestampableTrait;

    #[ORM\Id]
    #[ORM\Column(type: 'bigint', unique: true)]
    #[ORM\GeneratedValue(strategy: 'AUTO')]
    public private(set) int $id;

    #[ORM\Column(type: 'string', length: 20)]
    public string $game {
        get => $this->game;
        set => $this->game = $value;
    }

    #[ORM\Column(type: 'uuid')]
    public Uuid $cardId {
        get => $this->cardId;
        set => $this->cardId = $value;
    }

    #[ORM\Column(type: 'string', length: 20)]
    public string $finish {
        get => $this->finish;
        set => $this->finish = $value;
    }

    #[ORM\Column(type: 'string', length: 64)]
    public string $productId {
        get => $this->productId;
        set => $this->productId = $value;
    }

    #[ORM\Column]
    public int $stock = 0 {
        get => $this->stock;
        set => $this->stock = $value;
    }

    #[ORM\Column]
    public float $price = 0.0 {
        get => $this->price;
        set => $this->price = $value;
    }

    public function __construct(string $game, Uuid $cardId, string $finish, string $productId)
    {
        $this->game = $game;
        $this->cardId = $cardId;
        $this->finish = $finish;
        $this->productId = $productId;
        $this->initializeTimestamps();
    }
}
