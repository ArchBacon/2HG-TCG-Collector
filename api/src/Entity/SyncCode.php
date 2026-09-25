<?php declare(strict_types=1);

namespace App\Entity;

use App\Repository\SyncCodeRepository;
use DateTimeImmutable;
use Doctrine\ORM\Mapping as ORM;

/**
 * A short-lived, single-use code that lets another device take over a {@see User}. The redeeming
 * device drops its own user and data and continues as this one.
 *
 * The code itself is the primary key. It is short enough to type, so redemption must be
 * rate-limited to keep it from being brute-forced within its lifetime.
 */
#[ORM\Entity(repositoryClass: SyncCodeRepository::class)]
#[ORM\Table(name: 'sync_code')]
#[ORM\Index(name: 'idx_sync_code_expires_at', columns: ['expires_at'])]
class SyncCode
{
    public const string LIFETIME = '+1 hour';
    public const int LENGTH = 8;
    /** No 0/O, 1/I/L or U/V, so codes survive being read aloud or typed from another screen. */
    private const string ALPHABET = '23456789ABCDEFGHJKMNPQRSTWXYZ';

    #[ORM\Id]
    #[ORM\Column(type: 'string', length: self::LENGTH)]
    public private(set) string $code;

    #[ORM\ManyToOne(targetEntity: User::class)]
    #[ORM\JoinColumn(name: 'user_id', referencedColumnName: 'id', nullable: false, onDelete: 'CASCADE')]
    public private(set) User $user;

    #[ORM\Column]
    public private(set) DateTimeImmutable $createdAt;

    #[ORM\Column]
    public private(set) DateTimeImmutable $expiresAt;

    #[ORM\Column(nullable: true)]
    public private(set) ?DateTimeImmutable $usedAt = null;

    public function __construct(User $user)
    {
        $this->code = self::generateCode();
        $this->user = $user;
        $this->createdAt = new DateTimeImmutable();
        $this->expiresAt = $this->createdAt->modify(self::LIFETIME);
    }

    public function isRedeemable(DateTimeImmutable $now = new DateTimeImmutable()): bool
    {
        return $this->usedAt === null && $now < $this->expiresAt;
    }

    public function markUsed(): void
    {
        $this->usedAt = new DateTimeImmutable();
    }

    private static function generateCode(): string
    {
        $code = '';
        $max = strlen(self::ALPHABET) - 1;
        for ($i = 0; $i < self::LENGTH; $i++) {
            $code .= self::ALPHABET[random_int(0, $max)];
        }

        return $code;
    }
}
