<?php declare(strict_types=1);

namespace App\Repository;

use App\Entity\Announcement;
use App\Entity\DeviceToken;
use App\Entity\User;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\DBAL\ArrayParameterType;
use Doctrine\Persistence\ManagerRegistry;

/**
 * @extends ServiceEntityRepository<DeviceToken>
 */
final class DeviceTokenRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, DeviceToken::class);
    }

    /**
     * The user's devices with the "Wishlist cards in store" switch on.
     *
     * @return list<DeviceToken>
     */
    public function findWantingWishlist(User $user): array
    {
        return $this->findBy(['user' => $user, 'wishlistInStore' => true]);
    }

    /**
     * The devices an announcement goes to: the "News and events" switch on, and when it's for
     * collectors of some games, only devices of users with cards of those games in a list of
     * those types. Token per device id.
     *
     * @return array<int, string>
     */
    public function findForAnnouncement(Announcement $announcement): array
    {
        [$sql, $params, $types] = $this->announcementAudience($announcement, 'd.id, d.token');

        /** @var array<int, string> */
        return $this->getEntityManager()->getConnection()->fetchAllKeyValue($sql, $params, $types);
    }

    /**
     * How many users and devices {@see self::findForAnnouncement()} would reach now.
     *
     * @return array{users: int, devices: int}
     */
    public function countForAnnouncement(Announcement $announcement): array
    {
        [$sql, $params, $types] = $this->announcementAudience($announcement, 'COUNT(DISTINCT d.user_id) AS users, COUNT(*) AS devices');
        $row = $this->getEntityManager()->getConnection()->fetchAssociative($sql, $params, $types) ?: [];

        $count = static fn (mixed $value): int => is_numeric($value) ? (int) $value : 0; // MySQL counts come back as strings

        return ['users' => $count($row['users'] ?? 0), 'devices' => $count($row['devices'] ?? 0)];
    }

    /**
     * @return array{string, array<string, mixed>, array<string, ArrayParameterType>}
     */
    private function announcementAudience(Announcement $announcement, string $select): array
    {
        $sql = "SELECT $select FROM device_token d WHERE d.announcements = 1";
        if ($announcement->isForEveryone()) {
            return [$sql, [], []];
        }

        $sql .= ' AND EXISTS (
            SELECT 1 FROM card_list_entry e
            JOIN card_list l ON l.id = e.list_id
            WHERE l.user_id = d.user_id AND e.game IN (:games) AND l.type IN (:lists)
        )';

        return [
            $sql,
            ['games' => $announcement->games, 'lists' => $announcement->lists],
            ['games' => ArrayParameterType::STRING, 'lists' => ArrayParameterType::STRING],
        ];
    }

    /**
     * Deletes the token everywhere; Firebase said it's no longer valid.
     */
    public function deleteToken(string $token): void
    {
        $this->createQueryBuilder('d')
            ->delete()
            ->where('d.token = :token')
            ->setParameter('token', $token)
            ->getQuery()
            ->execute();
    }
}
