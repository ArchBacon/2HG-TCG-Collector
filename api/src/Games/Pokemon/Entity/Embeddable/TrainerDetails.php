<?php declare(strict_types=1);

namespace App\Games\Pokemon\Entity\Embeddable;

use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\Groups;

#[ORM\Embeddable]
class TrainerDetails
{
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 30, nullable: true)]
    public ?string $trainerType = null {
        get => $this->trainerType;
        set => $this->trainerType = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'text', nullable: true)]
    public ?string $effect = null {
        get => $this->effect;
        set => $this->effect = $value;
    }
}
