<?php declare(strict_types=1);

namespace App\Repository;

use App\Entity\AppliedChange;
use App\Entity\User;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;
use Symfony\Component\Uid\Uuid;

/**
 * @extends ServiceEntityRepository<AppliedChange>
 */
final class AppliedChangeRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, AppliedChange::class);
    }

    /**
     * Records a client change id. Returns false if it was already recorded, meaning the change
     * is a replay and must be skipped. Run it in the same transaction as the change itself, so
     * a failed change doesn't leave its id behind as "applied".
     */
    public function claim(Uuid $changeId, User $user): bool
    {
        $inserted = $this->getEntityManager()->getConnection()->executeStatement(
            'INSERT IGNORE INTO applied_change (id, user_id, applied_at) VALUES (:id, :user, :now)',
            [
                'id' => $changeId->toBinary(),
                'user' => $user->id->toBinary(),
                'now' => new \DateTimeImmutable()->format('Y-m-d H:i:s'),
            ],
        );

        return $inserted === 1;
    }

    /**
     * Deletes records older than $before. Returns the number of rows removed.
     */
    public function deleteOlderThan(\DateTimeImmutable $before): int
    {
        return $this->createQueryBuilder('a')
            ->delete()
            ->where('a.appliedAt < :before')
            ->setParameter('before', $before)
            ->getQuery()
            ->execute();
    }
}
