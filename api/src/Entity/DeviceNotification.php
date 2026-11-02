<?php declare(strict_types=1);

namespace App\Entity;

use App\Repository\DeviceNotificationRepository;
use DateTimeImmutable;
use Doctrine\ORM\Mapping as ORM;

/**
 * A notification sent to one device, for the app's list of received notifications and its unread
 * count. Recorded when Firebase accepted it for that device (see
 * {@see DeviceNotificationRepository::record()}); read once the app marks all as read.
 *
 * Kept on the API rather than in the app: the app isn't always running when a notification comes
 * in (on iOS it isn't woken for one at all), and the API knows what it sent.
 */
#[ORM\Entity(repositoryClass: DeviceNotificationRepository::class)]
#[ORM\Table(name: 'device_notification')]
#[ORM\Index(name: 'idx_device_notification_device_sent', columns: ['device_id', 'sent_at'])]
class DeviceNotification
{
    public const string WISHLIST = 'wishlist';
    public const string ANNOUNCEMENT = 'announcement';
    public const string TEST = 'test';

    #[ORM\Id]
    #[ORM\Column(type: 'bigint', unique: true)]
    #[ORM\GeneratedValue(strategy: 'AUTO')]
    public private(set) int $id;

    #[ORM\ManyToOne(targetEntity: DeviceToken::class)]
    #[ORM\JoinColumn(name: 'device_id', referencedColumnName: 'id', nullable: false, onDelete: 'CASCADE')]
    public private(set) DeviceToken $device;

    /** {@see self::WISHLIST}, {@see self::ANNOUNCEMENT} or {@see self::TEST}. */
    #[ORM\Column(length: 20)]
    public private(set) string $type;

    #[ORM\Column(length: 255)]
    public private(set) string $title;

    #[ORM\Column(length: 1000)]
    public private(set) string $body;

    #[ORM\Column(length: 40, nullable: true)]
    public private(set) ?string $route = null;

    #[ORM\Column]
    public private(set) DateTimeImmutable $sentAt;

    #[ORM\Column(nullable: true)]
    public private(set) ?DateTimeImmutable $readAt = null;

    private function __construct()
    {
        // Rows are inserted in bulk, see DeviceNotificationRepository::record()
    }
}
