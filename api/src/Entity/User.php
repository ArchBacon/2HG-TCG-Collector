<?php declare(strict_types=1);

namespace App\Entity;

use App\Repository\UserRepository;
use DateTimeImmutable;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Security\Core\User\UserInterface;
use Symfony\Component\Uid\Uuid;

/**
 * An anonymous app user, created server-side on the device's first startup. The device keeps
 * {@see self::$id} plus the plaintext secret handed out at creation; only its hash is stored.
 *
 * Redeeming a {@see SyncCode} gives another device the same user (with a fresh secret), so all
 * synced devices share one set of {@see CardList}s instead of merging copies.
 *
 * The secret is 256 random bits, not a user-chosen password, so a plain SHA-256 is enough to
 * store it: there is nothing to brute-force, and it keeps per-request authentication cheap. See
 * {@see \App\Security\ApiTokenAuthenticator} for how the device sends it.
 */
#[ORM\Entity(repositoryClass: UserRepository::class)]
#[ORM\Table(name: 'app_user')]
class User implements UserInterface
{
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    public private(set) Uuid $id;

    #[ORM\Column(type: 'string', length: 255)]
    public string $secretHash {
        get => $this->secretHash;
        set => $this->secretHash = $value;
    }

    #[ORM\Column]
    public private(set) DateTimeImmutable $createdAt;

    #[ORM\Column]
    public DateTimeImmutable $lastSeenAt {
        get => $this->lastSeenAt;
        set => $this->lastSeenAt = $value;
    }

    public function __construct(string $secretHash)
    {
        $this->id = Uuid::v7();
        $this->secretHash = $secretHash;
        $this->createdAt = new DateTimeImmutable();
        $this->lastSeenAt = $this->createdAt;
    }

    /**
     * Returns a new random secret. Store {@see self::hashSecret()} of it and hand the plaintext
     * to the device once; it can't be recovered afterwards.
     */
    public static function generateSecret(): string
    {
        return rtrim(strtr(base64_encode(random_bytes(32)), '+/', '-_'), '=');
    }

    public static function hashSecret(string $secret): string
    {
        return hash('sha256', $secret);
    }

    public function verifySecret(string $secret): bool
    {
        return hash_equals($this->secretHash, self::hashSecret($secret));
    }

    public function getRoles(): array
    {
        return ['ROLE_USER'];
    }

    public function getUserIdentifier(): string
    {
        return $this->id->toRfc4122();
    }
}
