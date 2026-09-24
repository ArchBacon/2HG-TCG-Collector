<?php declare(strict_types=1);

namespace App\Games\Pokemon\Entity\Embeddable;

use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\Groups;

#[ORM\Embeddable]
class PokemonDetails
{
    /** @var null|list<int> */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'json', nullable: true)]
    public ?array $dexIds = null {
        get => $this->dexIds;
        set {
            $this->dexIds = $value;
            $this->primaryDexId = $value[0] ?? null;
        }
    }

    #[ORM\Column(nullable: true)]
    public private(set) ?int $primaryDexId = null;

    #[Groups(['card:read'])]
    #[ORM\Column(nullable: true)]
    public ?int $hp = null {
        get => $this->hp;
        set => $this->hp = $value;
    }

    /** @var list<string> */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'json')]
    public array $colors = [] {
        get => $this->colors;
        set => $this->colors = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    public ?string $stage = null {
        get => $this->stage;
        set => $this->stage = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 60, nullable: true)]
    public ?string $evolveFrom = null {
        get => $this->evolveFrom;
        set => $this->evolveFrom = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    public ?string $level = null {
        get => $this->level;
        set => $this->level = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 30, nullable: true)]
    public ?string $suffix = null {
        get => $this->suffix;
        set => $this->suffix = $value;
    }

    /** @var null|array{name: string, effect: string} */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'json', nullable: true)]
    public ?array $item = null {
        get => $this->item;
        set => $this->item = $value;
    }

    /** @var list<array{type: string, name: string, effect: string}> */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'json')]
    public array $abilities = [] {
        get => $this->abilities;
        set => $this->abilities = $value;
    }

    /** @var list<array{cost?: list<string>, name: string, damage?: int|string, effect?: string}> */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'json')]
    public array $attacks = [] {
        get => $this->attacks;
        set => $this->attacks = $value;
    }

    /** @var list<array{type: string, value: string}> */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'json')]
    public array $weaknesses = [] {
        get => $this->weaknesses;
        set => $this->weaknesses = $value;
    }

    /** @var list<array{type: string, value: string}> */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'json')]
    public array $resistances = [] {
        get => $this->resistances;
        set => $this->resistances = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(nullable: true)]
    public ?int $retreat = null {
        get => $this->retreat;
        set => $this->retreat = $value;
    }
}
