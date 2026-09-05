<?php declare(strict_types=1);

namespace App\Games\Pokemon\Repository;

use App\Games\Pokemon\Entity\Card;
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
     * Returns every language's row for each id (see {@see Card::$lang}), not one per id.
     *
     * @param list<string> $tcgdexIds
     * @return list<Card>
     */
    public function findByTcgdexIds(array $tcgdexIds): array
    {
        if ($tcgdexIds === []) {
            return [];
        }

        return $this->createQueryBuilder('c')
            ->where('c.tcgdexId IN (:ids)')
            ->setParameter('ids', array_unique($tcgdexIds))
            ->getQuery()
            ->getResult();
    }
}
