<?php declare(strict_types=1);

namespace App\Entity;

use App\ApiResource\Traits\TimestampableTrait;
use App\Repository\DeviceTokenRepository;
use Doctrine\ORM\Mapping as ORM;

/**
 * A device's Firebase Cloud Messaging address, for push notifications to that device: its
 * Firebase Installation ID (FID), which FCM uses in place of the older registration tokens. A
 * user can have several: sync codes put several devices on one user.
 *
 * The app registers it on every start and whenever Firebase gives a new one. It belongs to one
 * device, so registering it again for another user (after redeeming a sync code) moves it. Ones
 * Firebase reports as no longer valid are deleted when a send fails on them.
 */
#[ORM\Entity(repositoryClass: DeviceTokenRepository::class)]
#[ORM\Table(name: 'device_token')]
#[ORM\UniqueConstraint(name: 'uniq_device_token_token', columns: ['token'])]
#[ORM\HasLifecycleCallbacks]
class DeviceToken
{
    use TimestampableTrait;

    public const int MAX_TOKEN_LENGTH = 255;

    #[ORM\Id]
    #[ORM\Column(type: 'bigint', unique: true)]
    #[ORM\GeneratedValue(strategy: 'AUTO')]
    public private(set) int $id;

    #[ORM\ManyToOne(targetEntity: User::class)]
    #[ORM\JoinColumn(name: 'user_id', referencedColumnName: 'id', nullable: false, onDelete: 'CASCADE')]
    public User $user {
        get => $this->user;
        set => $this->user = $value;
    }

    #[ORM\Column(type: 'string', length: self::MAX_TOKEN_LENGTH)]
    public private(set) string $token;

    /** `android` or `ios`, as the app says; only informative. */
    #[ORM\Column(type: 'string', length: 10, nullable: true)]
    public ?string $platform {
        get => $this->platform;
        set => $this->platform = $value;
    }

    /** The app's "Wishlist cards in store" switch, on this device. */
    #[ORM\Column]
    public bool $wishlistInStore = true {
        get => $this->wishlistInStore;
        set => $this->wishlistInStore = $value;
    }

    /** The app's "News and events" switch, on this device: the admin's announcements. */
    #[ORM\Column(options: ['default' => true])]
    public bool $announcements = true {
        get => $this->announcements;
        set => $this->announcements = $value;
    }

    public function __construct(User $user, string $token)
    {
        $this->user = $user;
        $this->token = $token;
        $this->platform = null;
        $this->initializeTimestamps();
    }
}
