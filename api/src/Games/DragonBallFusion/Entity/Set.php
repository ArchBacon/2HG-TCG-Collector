<?php declare(strict_types=1);

namespace App\Games\DragonBallFusion\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use App\Entity\Traits\TimestampableTrait;
use App\Games\DragonBallFusion\Repository\SetRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\Groups;
use Symfony\Component\Serializer\Attribute\SerializedName;
use Symfony\Component\Uid\Uuid;

#[ApiResource(
    operations: [new GetCollection(), new Get()],
    routePrefix: '/dragonballfusion',
    normalizationContext: ['groups' => ['set:read']],
)]
#[ORM\Entity(repositoryClass: SetRepository::class)]
#[ORM\Table(name: 'dragonballfusion_set')]
#[ORM\UniqueConstraint(name: 'uniq_dragonballfusion_set_set_id', columns: ['set_id'])]
#[ORM\HasLifecycleCallbacks]
class Set
{
    use TimestampableTrait;

    #[Groups(['set:read'])]
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    #[ORM\GeneratedValue(strategy: 'NONE')]
    public private(set) Uuid $id;

    /**
     * apitcg's own set code, e.g. "fb01" for "Awakened pulse". There's no dedicated sets
     * endpoint with richer metadata (release date, card count, ...) like Pokemon/OnePiece have —
     * this and {@see self::$name} are denormalized from the `set` object embedded in every card.
     */
    #[Groups(['set:read'])]
    #[SerializedName('id')]
    #[ORM\Column(type: 'string', length: 20)]
    public string $setId {
        get => $this->setId;
        set => $this->setId = $value;
    }

    #[Groups(['set:read'])]
    #[SerializedName('name')]
    #[ORM\Column(type: 'string', length: 255)]
    public string $name {
        get => $this->name;
        set => $this->name = $value;
    }

    public function __construct(
        string $setId,
        string $name,
    ) {
        $this->id = Uuid::v7();
        $this->setId = $setId;
        $this->name = $name;
        $this->initializeTimestamps();
    }
}
