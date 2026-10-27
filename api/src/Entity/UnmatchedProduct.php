<?php declare(strict_types=1);

namespace App\Entity;

use App\ApiResource\Traits\TimestampableTrait;
use App\Repository\UnmatchedProductRepository;
use Doctrine\ORM\Mapping as ORM;

/**
 * A shop product the matcher ({@see \App\Service\ProductMatcher}) couldn't confidently pair
 * with a card. Parked here for manual review, with the latest record from the shop and why it
 * wasn't matched; once someone links it, it becomes a {@see CardListing} and this row is removed.
 *
 * The game is null while not even the set is known. Product ids are the shop's, unique over all
 * games: there's one shop.
 */
#[ORM\Entity(repositoryClass: UnmatchedProductRepository::class)]
#[ORM\Table(name: 'product_unmatched')]
#[ORM\UniqueConstraint(name: 'uniq_unmatched_product_product', columns: ['product_id'])]
#[ORM\HasLifecycleCallbacks]
class UnmatchedProduct
{
    use TimestampableTrait;

    #[ORM\Id]
    #[ORM\Column(type: 'bigint', unique: true)]
    #[ORM\GeneratedValue(strategy: 'AUTO')]
    public private(set) int $id;

    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    public ?string $game {
        get => $this->game;
        set => $this->game = $value;
    }

    #[ORM\Column(type: 'string', length: 64)]
    public string $productId {
        get => $this->productId;
        set => $this->productId = $value;
    }

    /** Product name from the shop feed, so a human reviewing the backlog can eyeball what it is. */
    #[ORM\Column(type: 'string', length: 255)]
    public string $name {
        get => $this->name;
        set => $this->name = $value;
    }

    /** Why the matcher couldn't link it, e.g. `No card #004 in Evolving Skies.` */
    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $reason = null {
        get => $this->reason;
        set => $this->reason = $value;
    }

    /**
     * The full raw record from the shop feed, kept for whatever the manual matcher needs.
     * @var array<string, mixed>|null
     */
    #[ORM\Column(type: 'json', nullable: true)]
    public ?array $payload = null {
        get => $this->payload;
        set => $this->payload = $value;
    }

    /**
     * @param array<string, mixed>|null $payload
     */
    public function __construct(?string $game, string $productId, string $name, ?array $payload = null)
    {
        $this->game = $game;
        $this->productId = $productId;
        $this->name = $name;
        $this->payload = $payload;
        $this->initializeTimestamps();
    }
}
