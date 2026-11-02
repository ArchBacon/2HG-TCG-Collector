<?php declare(strict_types=1);

namespace App\Repository;

use App\Entity\Announcement;
use DateTimeImmutable;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

/**
 * @extends ServiceEntityRepository<Announcement>
 */
final class AnnouncementRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, Announcement::class);
    }

    /**
     * Scheduled announcements whose time has come, oldest first.
     *
     * @return list<Announcement>
     */
    public function findDue(DateTimeImmutable $now): array
    {
        /** @var list<Announcement> */
        return $this->createQueryBuilder('a')
            ->where('a.status = :scheduled AND a.sendAt <= :now')
            ->setParameter('scheduled', Announcement::SCHEDULED)
            ->setParameter('now', $now)
            ->orderBy('a.sendAt')
            ->getQuery()
            ->getResult();
    }

    /**
     * The scheduled ones (next first), then the rest (newest first), at most $limit of those.
     *
     * @return array{scheduled: list<Announcement>, past: list<Announcement>}
     */
    public function findForAdmin(int $limit): array
    {
        /** @var list<Announcement> $scheduled */
        $scheduled = $this->createQueryBuilder('a')
            ->where('a.status = :scheduled')
            ->setParameter('scheduled', Announcement::SCHEDULED)
            ->orderBy('a.sendAt')
            ->getQuery()
            ->getResult();

        /** @var list<Announcement> $past */
        $past = $this->createQueryBuilder('a')
            ->where('a.status != :scheduled')
            ->setParameter('scheduled', Announcement::SCHEDULED)
            ->orderBy('a.sendAt', 'DESC')
            ->addOrderBy('a.id', 'DESC')
            ->setMaxResults($limit)
            ->getQuery()
            ->getResult();

        return ['scheduled' => $scheduled, 'past' => $past];
    }

    /**
     * Takes a scheduled announcement for sending, once: false when another run (or a cancel) got
     * there first.
     */
    public function claim(Announcement $announcement): bool
    {
        $claimed = $this->getEntityManager()->getConnection()->executeStatement(
            'UPDATE announcement SET status = :sending WHERE id = :id AND status = :scheduled',
            ['sending' => Announcement::SENDING, 'id' => $announcement->id, 'scheduled' => Announcement::SCHEDULED],
        ) === 1;
        if ($claimed) {
            $announcement->markSending(); // The entity in memory as the row now is
        }

        return $claimed;
    }
}
