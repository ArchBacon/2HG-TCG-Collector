<?php declare(strict_types=1);

namespace App\Entity;

use App\Repository\AppliedChangeRepository;
use DateTimeImmutable;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Uid\Uuid;

/**
 * Records each client-side change id that has already been applied, so a device replaying its
 * offline queue after a dropped response does not apply the same quantity delta twice. Rows only
 * need to outlive a client's retry window and can be pruned by {@see self::$appliedAt}.
 */
#[ORM\Entity(repositoryClass: AppliedChangeRepository::class)]
#[ORM\Table(name: 'applied_change')]
#[ORM\Index(name: 'idx_applied_change_applied_at', columns: ['applied_at'])]
class AppliedChange
{
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    public private(set) Uuid $id;

    #[ORM\ManyToOne(targetEntity: User::class)]
    #[ORM\JoinColumn(name: 'user_id', referencedColumnName: 'id', nullable: false, onDelete: 'CASCADE')]
    public private(set) User $user;

    #[ORM\Column]
    public private(set) DateTimeImmutable $appliedAt;

    public function __construct(Uuid $id, User $user)
    {
        $this->id = $id;
        $this->user = $user;
        $this->appliedAt = new DateTimeImmutable();
    }
}
