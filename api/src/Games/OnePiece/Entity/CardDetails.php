<?php declare(strict_types=1);

namespace App\Games\OnePiece\Entity;

use Symfony\Component\Serializer\Attribute\Groups;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Embeddable]
class CardDetails
{
    /** @var string constructed from hash('xxh3', 'setcode|printid|imageuri') api data */
    #[ORM\Column(type: 'string', length: 64)]
    public string $uniqueId {
        get => $this->uniqueId;
        set => $this->uniqueId = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 30)]
    public string $color {
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
    #[ORM\Column(nullable: true)]
    public ?int $power = null {
        get => $this->power;
        set => $this->power = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(nullable: true)]
    public ?int $life = null {
        get => $this->life;
        set => $this->life = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(nullable: true)]
    public ?int $counterAmount = null {
        get => $this->counterAmount;
        set => $this->counterAmount = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $attribute = null {
        get => $this->attribute;
        set => $this->attribute = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $subTypes = null {
        get => $this->subTypes;
        set => $this->subTypes = $value;
    }
}
