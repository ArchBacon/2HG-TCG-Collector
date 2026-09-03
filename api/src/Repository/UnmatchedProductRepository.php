<?php declare(strict_types=1);

namespace App\Repository;

use App\Entity\UnmatchedProduct;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

/**
 * @extends ServiceEntityRepository<UnmatchedProduct>
 */
final class UnmatchedProductRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, UnmatchedProduct::class);
    }

    /**
     * Records (or refreshes) a product the automatcher couldn't pair with a card.
     *
     * @param array<string,mixed>|null $payload
     */
    public function upsert(string $game, string $productId, string $name, ?array $payload = null): UnmatchedProduct
    {
        $product = $this->findOneBy(['game' => $game, 'productId' => $productId]);

        if ($product === null) {
            $product = new UnmatchedProduct($game, $productId, $name, $payload);
            $this->getEntityManager()->persist($product);
        } else {
            $product->name = $name;
            $product->payload = $payload;
        }

        $this->getEntityManager()->flush();

        return $product;
    }

    /** Called once a human (or a smarter automatcher pass) matches this product to a card. */
    public function remove(UnmatchedProduct $product): void
    {
        $this->getEntityManager()->remove($product);
        $this->getEntityManager()->flush();
    }
}
