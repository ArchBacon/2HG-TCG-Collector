<?php declare(strict_types=1);

namespace App\Repository;

use App\Entity\WishlistPush;
use DateTimeImmutable;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

/**
 * @extends ServiceEntityRepository<WishlistPush>
 */
final class WishlistPushRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, WishlistPush::class);
    }

    /**
     * Pushes still to send (not sent, not given up), oldest first, from after id $afterId.
     *
     * @return list<WishlistPush>
     */
    public function findUnsent(int $limit, int $afterId = 0): array
    {
        /** @var list<WishlistPush> */
        return $this->createQueryBuilder('p')
            ->addSelect('u')
            ->join('p.user', 'u')
            ->where('p.sentAt IS NULL AND p.failedAt IS NULL AND p.id > :afterId')
            ->setParameter('afterId', $afterId)
            ->orderBy('p.id')
            ->setMaxResults($limit)
            ->getQuery()
            ->getResult();
    }

    /**
     * Deletes pushes built before $before, sent or not, with their notices (ON DELETE CASCADE).
     * Returns the number of pushes removed.
     */
    public function deleteOlderThan(DateTimeImmutable $before): int
    {
        return $this->createQueryBuilder('p')
            ->delete()
            ->where('p.createdAt < :before')
            ->setParameter('before', $before)
            ->getQuery()
            ->execute();
    }
}
