<?php declare(strict_types=1);

namespace App\Service;

use App\Entity\CardListing;
use App\Entity\UnmatchedProduct;
use App\Enum\Game;
use App\Repository\CardListingRepository;
use App\Repository\UnmatchedProductRepository;
use Doctrine\ORM\EntityManagerInterface;
use DomainException;
use Symfony\Component\Uid\Uuid;
use function is_numeric;
use function sprintf;

/**
 * Manually links an {@see UnmatchedProduct} to a card: upserts its {@see CardListing} and
 * clears it from the unmatched backlog.
 */
final readonly class ProductLinkService
{
    public function __construct(
        private CardListingRepository $listings,
        private UnmatchedProductRepository $unmatched,
        private EntityManagerInterface $entityManager,
    ) {}

    /**
     * @throws DomainException when the card doesn't exist, or the card + finish already
     *         belongs to another product (product_listing allows one product per card + finish).
     */
    public function link(UnmatchedProduct $product, Uuid $cardId, string $finish): CardListing
    {
        $game = Game::tryFrom($product->game)
            ?? throw new DomainException(sprintf('Unknown game "%s".', $product->game));

        if ($this->entityManager->find($game->cardClass(), $cardId) === null) {
            throw new DomainException('That card does not exist.');
        }

        $taken = $this->listings->findOneBy(['game' => $product->game, 'cardId' => $cardId, 'finish' => $finish]);
        if ($taken !== null && $taken->productId !== $product->productId) {
            throw new DomainException(sprintf('That card (%s) is already linked to product "%s".', $finish, $taken->productId));
        }

        // Stock and price come from the latest feed record parked on the unmatched row.
        $payload = $product->payload ?? [];
        $stock = $payload['stock'] ?? null;
        $price = $payload['price'] ?? null;

        $listing = $this->listings->upsert(
            game: $product->game,
            productId: $product->productId,
            cardId: $cardId,
            finish: $finish,
            stock: is_numeric($stock) ? (int) $stock : 0,
            price: is_numeric($price) ? (float) $price : 0.0,
        );

        $this->unmatched->remove($product);

        return $listing;
    }
}
