<?php declare(strict_types=1);

namespace App\Games\OnePiece\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use App\ApiResource\Traits\TimestampableTrait;
use App\Games\OnePiece\Repository\SetRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\Groups;
use Symfony\Component\Serializer\Attribute\SerializedName;
use Symfony\Component\Uid\Uuid;

#[ApiResource(
    operations: [new GetCollection(), new Get()],
    routePrefix: '/onepiece',
    normalizationContext: ['groups' => ['set:read']],
)]
#[ORM\Entity(repositoryClass: SetRepository::class)]
#[ORM\Table(name: 'onepiece_set')]
#[ORM\UniqueConstraint(name: 'uniq_onepiece_set_set_id', columns: ['set_id'])]
#[ORM\HasLifecycleCallbacks]
class Set
{
    use TimestampableTrait;

    #[Groups(['set:read'])]
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    #[ORM\GeneratedValue(strategy: 'NONE')]
    public private(set) Uuid $id;

    #[Groups(['set:read'])]
    #[SerializedName('set_id')]
    #[ORM\Column(type: 'string', length: 10)]
    public string $setId {
        get => $this->setId;
        set => $this->setId = $value;
    }

    #[Groups(['set:read'])]
    #[SerializedName('set_name')]
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
