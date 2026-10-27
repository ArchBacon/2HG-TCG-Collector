<?php declare(strict_types=1);

namespace App\Service;

use App\Entity\CardListing;
use App\Entity\UnmatchedProduct;
use App\Enum\Game;
use App\Repository\CardListingRepository;
use Doctrine\ORM\EntityManagerInterface;
use DomainException;
use Symfony\Component\Uid\Uuid;
use function sprintf;

/**
 * Manually links an {@see UnmatchedProduct} to a card: creates its {@see CardListing}, with the
 * conditions from the latest shop record, and clears it from the unmatched backlog.
 */
final readonly class ProductLinkService
{
    public function __construct(
        private CardListingRepository $listings,
        private EntityManagerInterface $entityManager,
    ) {}

    /**
     * @throws DomainException when the card doesn't exist, or the card + finish already
     *         belongs to another product (product_listing allows one product per card + finish).
     */
    public function link(UnmatchedProduct $product, Game $game, Uuid $cardId, string $finish): CardListing
    {
        if ($this->entityManager->find($game->cardClass(), $cardId) === null) {
            throw new DomainException('That card does not exist.');
        }

        $taken = $this->listings->findOneBy(['game' => $game->value, 'cardId' => $cardId, 'finish' => $finish]);
        if ($taken !== null && $taken->productId !== $product->productId) {
            throw new DomainException(sprintf('That card (%s) is already linked to product "%s".', $finish, $taken->productId));
        }

        $listing = $this->listings->findOneBy(['productId' => $product->productId]);
        if ($listing === null) {
            $listing = new CardListing($game->value, $cardId, $finish, $product->productId);
            $this->entityManager->persist($listing);
        } else {
            $listing->game = $game->value;
            $listing->cardId = $cardId;
            $listing->finish = $finish;
        }
        $listing->syncConditions(ShopFeed::conditions($product->payload ?? []));

        $this->entityManager->remove($product);
        $this->entityManager->flush();

        return $listing;
    }
}
