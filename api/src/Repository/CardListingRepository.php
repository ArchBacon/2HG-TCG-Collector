<?php declare(strict_types=1);

namespace App\Repository;

use App\Entity\CardListing;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;
use Symfony\Component\Uid\Uuid;

/**
 * @extends ServiceEntityRepository<CardListing>
 */
final class CardListingRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, CardListing::class);
    }

    /**
     * Finds the listing for (game, productId) and updates it, or creates a new one.
     * productId is the natural key here: it's the shop's own identity for a single SKU, and
     * the automatcher may reassign which card/finish it points at between runs.
     */
    public function upsert(string $game, string $productId, Uuid $cardId, string $finish, int $stock, float $price): CardListing
    {
        $listing = $this->findOneBy(['game' => $game, 'productId' => $productId]);

        if ($listing === null) {
            $listing = new CardListing($game, $cardId, $finish, $productId);
            $this->getEntityManager()->persist($listing);
        } else {
            $listing->cardId = $cardId;
            $listing->finish = $finish;
        }

        $listing->stock = $stock;
        $listing->price = $price;

        $this->getEntityManager()->flush();

        return $listing;
    }
}
