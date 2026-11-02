<?php declare(strict_types=1);

namespace App\Repository;

use App\Entity\DeviceNotification;
use App\Entity\DeviceToken;
use DateTimeImmutable;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

use function array_chunk;
use function array_fill;
use function array_push;
use function count;
use function implode;
use function mb_substr;

/**
 * @extends ServiceEntityRepository<DeviceNotification>
 */
final class DeviceNotificationRepository extends ServiceEntityRepository
{
    /** Rows per INSERT when recording for many devices. */
    private const int CHUNK = 500;

    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, DeviceNotification::class);
    }

    /**
     * Records a notification as sent to these devices (their ids), unread.
     *
     * @param list<int> $deviceIds
     */
    public function record(array $deviceIds, string $type, string $title, string $body, ?string $route): void
    {
        $connection = $this->getEntityManager()->getConnection();
        $now = new DateTimeImmutable()->format('Y-m-d H:i:s');
        $title = mb_substr($title, 0, 255);
        $body = mb_substr($body, 0, 1000);

        foreach (array_chunk($deviceIds, self::CHUNK) as $chunk) {
            $values = implode(', ', array_fill(0, count($chunk), '(?, ?, ?, ?, ?, ?)'));
            $params = [];
            foreach ($chunk as $deviceId) {
                array_push($params, $deviceId, $type, $title, $body, $route, $now);
            }
            $connection->executeStatement(
                "INSERT INTO device_notification (device_id, type, title, body, route, sent_at) VALUES $values",
                $params,
            );
        }
    }

    /**
     * The device's notifications, newest first.
     *
     * @return list<DeviceNotification>
     */
    public function findForDevice(DeviceToken $device, int $limit): array
    {
        return $this->findBy(['device' => $device], ['sentAt' => 'DESC', 'id' => 'DESC'], $limit);
    }

    public function countUnread(DeviceToken $device): int
    {
        return $this->count(['device' => $device, 'readAt' => null]);
    }

    /**
     * Marks all of the device's notifications read. Returns how many were unread.
     */
    public function markAllRead(DeviceToken $device): int
    {
        return $this->createQueryBuilder('n')
            ->update()
            ->set('n.readAt', ':now')
            ->where('n.device = :device AND n.readAt IS NULL')
            ->setParameter('now', new DateTimeImmutable())
            ->setParameter('device', $device)
            ->getQuery()
            ->execute();
    }

    /**
     * Deletes notifications sent before $before. Returns how many.
     */
    public function deleteOlderThan(DateTimeImmutable $before): int
    {
        return $this->createQueryBuilder('n')
            ->delete()
            ->where('n.sentAt < :before')
            ->setParameter('before', $before)
            ->getQuery()
            ->execute();
    }
}
