<?php declare(strict_types=1);

namespace App\ApiResource\Traits;

use DateTimeImmutable;
use Doctrine\ORM\Mapping as ORM;

/**
 * Requires the using entity to be annotated with #[ORM\HasLifecycleCallbacks]
 * and to call {@see self::initializeTimestamps()} from its constructor.
 */
trait TimestampableTrait
{
    #[ORM\Column]
    public protected(set) DateTimeImmutable $createdAt;

    #[ORM\Column]
    public protected(set) DateTimeImmutable $updatedAt;

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
