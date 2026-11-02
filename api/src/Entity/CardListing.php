<?php declare(strict_types=1);

namespace App\Entity;

use App\ApiResource\Traits\TimestampableTrait;
use App\Repository\CardListingRepository;
use App\Service\ShopFeed;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Uid\Uuid;

/**
 * A shop product linked to one card printing + finish: by {@see \App\Service\ProductMatcher}
 * when stock comes in, or by hand in the admin. The link stays once made; stock and price are per
 * condition ({@see CardListingCondition}), and a product without any is linked all the same.
 *
 * Deliberately not game-specific and not FK-linked to any game's card table, the same as
 * {@see ImageJobQueue}: {@see self::$cardId} is a loose reference, resolved per
 * {@see self::$game}. `finish` is a plain string rather than an enum since the vocabulary is
 * per-game (MTG: nonfoil/foil/etched; Pokémon: normal/holo/reverse).
 *
 * @phpstan-import-type ShopCondition from ShopFeed
 */
#[ORM\Entity(repositoryClass: CardListingRepository::class)]
#[ORM\Table(name: 'product_listing')]
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

    /** @var Collection<int, CardListingCondition> */
    #[ORM\OneToMany(targetEntity: CardListingCondition::class, mappedBy: 'listing', cascade: ['persist'], orphanRemoval: true)]
    public private(set) Collection $conditions;

    public function __construct(string $game, Uuid $cardId, string $finish, string $productId)
    {
        $this->game = $game;
        $this->cardId = $cardId;
        $this->finish = $finish;
        $this->productId = $productId;
        $this->conditions = new ArrayCollection();
        $this->initializeTimestamps();
    }

    /**
     * Makes the conditions what the shop sent: updates the known ones, adds new ones, and removes
     * the ones the shop no longer has. Returns whether that brought it into stock: none of its
     * conditions in stock before, and at least one now (for wishlist notifications).
     *
     * @param list<ShopCondition> $conditions
     */
    public function syncConditions(array $conditions): bool
    {
        $wasInStock = $this->isInStock();
        $known = [];
        foreach ($this->conditions as $condition) {
            $known[$condition->variantId] = $condition;
        }

        $sent = [];
        foreach ($conditions as $data) {
            $condition = $known[$data['variantId']] ?? null;
            if ($condition === null) {
                $condition = new CardListingCondition($this, $data['variantId'], $data['condition']);
                $this->conditions->add($condition);
            }
            $condition->condition = $data['condition'];
            $condition->stock = $data['stock'];
            $condition->price = $data['price'];
            $sent[$data['variantId']] = true;
        }

        foreach ($known as $variantId => $condition) {
            if (!isset($sent[$variantId])) {
                $this->conditions->removeElement($condition);
            }
        }

        return !$wasInStock && $this->isInStock();
    }

    /** Whether any of its conditions is in stock. */
    public function isInStock(): bool
    {
        return $this->conditions->exists(static fn (int $key, CardListingCondition $condition): bool => $condition->stock > 0);
    }
}
