<?php declare(strict_types=1);

namespace App\Games\Lorcana\Entity;

use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\Groups;

#[ORM\Embeddable]
class CardDetails
{
    #[ORM\Column(type: 'string', length: 20)]
    public string $uniqueId {
        get => $this->uniqueId;
        set => $this->uniqueId = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 60)]
    public string $color {
        get => $this->color;
        set => $this->color = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column]
    public int $cost {
        get => $this->cost;
        set => $this->cost = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column]
    public bool $inkable {
        get => $this->inkable;
        set => $this->inkable = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $classifications = null {
        get => $this->classifications;
        set => $this->classifications = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $abilities = null {
        get => $this->abilities;
        set => $this->abilities = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(nullable: true)]
    public ?int $strength = null {
        get => $this->strength;
        set => $this->strength = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(nullable: true)]
    public ?int $willpower = null {
        get => $this->willpower;
        set => $this->willpower = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(nullable: true)]
    public ?int $lore = null {
        get => $this->lore;
        set => $this->lore = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 100, nullable: true)]
    public ?string $franchise = null {
        get => $this->franchise;
        set => $this->franchise = $value;
    }
}
