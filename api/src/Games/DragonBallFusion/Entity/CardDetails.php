<?php declare(strict_types=1);

namespace App\Games\DragonBallFusion\Entity;

use Symfony\Component\Serializer\Attribute\Groups;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Embeddable]
class CardDetails
{
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    public ?string $color = null {
        get => $this->color;
        set => $this->color = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(nullable: true)]
    public ?int $cost = null {
        get => $this->cost;
        set => $this->cost = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 10, nullable: true)]
    public ?string $specifiedCost = null {
        get => $this->specifiedCost;
        set => $this->specifiedCost = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(nullable: true)]
    public ?int $power = null {
        get => $this->power;
        set => $this->power = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(nullable: true)]
    public ?int $comboPower = null {
        get => $this->comboPower;
        set => $this->comboPower = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $features = null {
        get => $this->features;
        set => $this->features = $value;
    }
}
