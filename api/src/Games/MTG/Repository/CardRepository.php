<?php declare(strict_types=1);

namespace App\Games\MTG\Repository;

use App\Games\MTG\Entity\Card;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

/**
 * @extends ServiceEntityRepository<Card>
 */
final class CardRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, Card::class);
    }

    /**
     * @param list<string> $scryfallIds
     * @return list<Card>
     */
    public function findByScryfallIds(array $scryfallIds): array
    {
        if ($scryfallIds === []) {
            return [];
        }

        return $this->createQueryBuilder('c')
            ->where('c.details.scryfallId IN (:ids)')
            ->setParameter('ids', array_unique($scryfallIds))
            ->getQuery()
            ->getResult();
    }
}
