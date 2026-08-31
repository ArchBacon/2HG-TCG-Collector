<?php declare(strict_types=1);

namespace App\Entity\Traits;

use DateTimeImmutable;
use Doctrine\ORM\Mapping as ORM;

/**
 * Requires the using entity to be annotated with #[ORM\HasLifecycleCallbacks]
 * and to call {@see self::initializeTimestamps()} from its constructor.
 *
 * Uses asymmetric visibility (PHP 8.4) so callers can read $entity->createdAt
 * directly while only this class can write it. Doctrine hydrates these via
 * ReflectionProperty::setRawValue() on PHP >= 8.4, which bypasses private(set)
 * (and would bypass property hooks too), so DB loading is unaffected.
 */
trait TimestampableTrait
{
    #[ORM\Column]
    public private(set) DateTimeImmutable $createdAt;

    #[ORM\Column]
    public private(set) DateTimeImmutable $updatedAt;

    #[ORM\PreUpdate]
    public function touchUpdatedAt(): void
    {
        $this->updatedAt = new DateTimeImmutable();
    }

    private function initializeTimestamps(): void
    {
        $this->createdAt = new DateTimeImmutable();
        $this->updatedAt = $this->createdAt;
    }
}
