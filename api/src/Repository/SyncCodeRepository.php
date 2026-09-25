<?php declare(strict_types=1);

namespace App\Repository;

use App\Entity\SyncCode;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

/**
 * @extends ServiceEntityRepository<SyncCode>
 */
final class SyncCodeRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, SyncCode::class);
    }

    /**
     * Returns the code if it exists and can still be redeemed, otherwise null.
     */
    public function findRedeemable(string $code): ?SyncCode
    {
        $syncCode = $this->find(strtoupper(trim($code)));

        return $syncCode?->isRedeemable() ? $syncCode : null;
    }

    /**
     * Deletes expired and used codes. Returns the number of rows removed.
     */
    public function deleteExpired(): int
    {
        return $this->createQueryBuilder('s')
            ->delete()
            ->where('s.expiresAt < :now OR s.usedAt IS NOT NULL')
            ->setParameter('now', new \DateTimeImmutable())
            ->getQuery()
            ->execute();
    }
}
