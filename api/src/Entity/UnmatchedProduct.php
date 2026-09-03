<?php declare(strict_types=1);

namespace App\Entity;

use App\Entity\Traits\TimestampableTrait;
use App\Repository\UnmatchedProductRepository;
use Doctrine\ORM\Mapping as ORM;

/**
 * A shop product the automatcher couldn't confidently pair with a card. Parked here for
 * manual review; once someone matches it (by hand or a smarter matcher pass), upsert a
 * {@see CardListing} for it and remove this row via {@see UnmatchedProductRepository::remove()}.
 */
#[ORM\Entity(repositoryClass: UnmatchedProductRepository::class)]
#[ORM\Table(name: 'unmatched_product')]
#[ORM\UniqueConstraint(name: 'uniq_unmatched_product_game_product', columns: ['game', 'product_id'])]
#[ORM\HasLifecycleCallbacks]
class UnmatchedProduct
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
    public function __construct(string $game, string $productId, string $name, ?array $payload = null)
    {
        $this->game = $game;
        $this->productId = $productId;
        $this->name = $name;
        $this->payload = $payload;
        $this->initializeTimestamps();
    }
}
