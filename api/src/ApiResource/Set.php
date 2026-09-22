<?php declare(strict_types=1);

namespace App\ApiResource;

use App\ApiResource\Traits\TimestampableTrait;
use App\Enum\Game;
use DateTimeImmutable;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\Context;
use Symfony\Component\Serializer\Attribute\Groups;
use Symfony\Component\Serializer\Normalizer\DateTimeNormalizer;
use Symfony\Component\Uid\Uuid;

#[ORM\MappedSuperclass]
#[ORM\HasLifecycleCallbacks]
abstract class Set
{
    use TimestampableTrait;

    #[Groups(['set:read'])]
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    #[ORM\GeneratedValue(strategy: 'NONE')]
    public protected(set) Uuid $id;

    #[Groups(['set:read'])]
    #[ORM\Column(type: 'string', length: 20)]
    public string $code {
        get => $this->code;
        set => $this->code = $value;
    }

    #[Groups(['set:read'])]
    #[ORM\Column(type: 'string', length: 16)]
    abstract public Game $tcg { get; }

    #[Groups(['set:read'])]
    #[ORM\Column(type: 'string', length: 255)]
    public string $name {
        get => $this->name;
        set => $this->name = $value;
    }

    #[Groups(['set:read'])]
    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $type = null {
        get => $this->type;
        set => $this->type = $value;
    }

    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    public ?string $block = null {
        get => $this->block;
        set => $this->block = $value;
    }

    #[Groups(['set:read'])]
    #[ORM\Column(nullable: true)]
    public ?int $cardCount = null {
        get => $this->cardCount;
        set => $this->cardCount = $value;
    }

    #[Groups(['set:read'])]
    abstract public ?string $icon { get; }

    #[Groups(['set:read'])]
    #[ORM\Column(type: 'date_immutable', nullable: true)]
    #[Context([DateTimeNormalizer::FORMAT_KEY => 'Y-m-d'])]
    public ?DateTimeImmutable $releasedAt = null {
        get => $this->releasedAt;
        set => $this->releasedAt = $value;
    }

    public function __construct()
    {
        $this->id = Uuid::v7();
        $this->initializeTimestamps();
    }
}
