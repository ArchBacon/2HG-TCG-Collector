<?php declare(strict_types=1);

namespace App\Entity;

use App\ApiResource\Traits\TimestampableTrait;
use Doctrine\ORM\Mapping as ORM;

/**
 * Stock and price of one condition of a shop product ({@see CardListing}): a variant in the shop
 * (PrestaShop's `id_product_attribute`). The shop's cart takes the product id with this condition
 * as text, so {@see self::$condition} is kept exactly as the shop names it.
 */
#[ORM\Entity]
#[ORM\Table(name: 'product_listing_condition')]
#[ORM\UniqueConstraint(name: 'uniq_listing_condition_variant', columns: ['listing_id', 'variant_id'])]
#[ORM\HasLifecycleCallbacks]
class CardListingCondition
{
    use TimestampableTrait;

    #[ORM\Id]
    #[ORM\Column(type: 'bigint', unique: true)]
    #[ORM\GeneratedValue(strategy: 'AUTO')]
    public private(set) int $id;

    #[ORM\ManyToOne(inversedBy: 'conditions')]
    #[ORM\JoinColumn(nullable: false, onDelete: 'CASCADE')]
    public private(set) CardListing $listing;

    /** The shop's id of this variant of the product. */
    #[ORM\Column(type: 'string', length: 64)]
    public private(set) string $variantId;

    /** As the shop names it, e.g. "Near Mint" or "played". */
    #[ORM\Column(name: 'condition_name', type: 'string', length: 60)]
    public string $condition {
        get => $this->condition;
        set => $this->condition = $value;
    }

    #[ORM\Column]
    public int $stock = 0 {
        get => $this->stock;
        set => $this->stock = $value;
    }

    /** Excluding VAT in the shop's data, but that's its naming: it's the price customers pay. */
    #[ORM\Column]
    public float $price = 0.0 {
        get => $this->price;
        set => $this->price = $value;
    }

    public function __construct(CardListing $listing, string $variantId, string $condition)
    {
        $this->listing = $listing;
        $this->variantId = $variantId;
        $this->condition = $condition;
        $this->initializeTimestamps();
    }
}
