<?php declare(strict_types=1);

namespace App\Games\Pokemon\Entity;

use App\Games\Pokemon\Entity\Embeddable\EnergyDetails;
use App\Games\Pokemon\Entity\Embeddable\PokemonDetails;
use App\Games\Pokemon\Entity\Embeddable\TrainerDetails;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\Groups;

/**
 * Only the block matching the card's category is exposed, the others read as null.
 * Doctrine always hydrates embeddables (even when every column is null), so emptiness
 * is decided by the required field of each block. Doctrine reads raw values, bypassing these hooks.
 */
#[ORM\Embeddable]
class CardDetails
{
    #[ORM\Column(type: 'string', length: 20)]
    public string $uniqueId {
        get => $this->uniqueId;
        set => $this->uniqueId = $value;
    }

    /** @var list<string> */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'json')]
    public array $finishes = [] {
        get => $this->finishes;
        set => $this->finishes = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    public ?string $regulationMark = null {
        get => $this->regulationMark;
        set => $this->regulationMark = $value;
    }

    /** @var array<string, bool> */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'json')]
    public array $legalities = [] {
        get => $this->legalities;
        set => $this->legalities = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Embedded(class: PokemonDetails::class)]
    public ?PokemonDetails $pokemon = null {
        get => $this->trainer === null && $this->energy === null ? $this->pokemon : null;
        set => $this->pokemon = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Embedded(class: TrainerDetails::class)]
    public ?TrainerDetails $trainer = null {
        get => $this->trainer?->trainerType !== null ? $this->trainer : null;
        set => $this->trainer = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Embedded(class: EnergyDetails::class)]
    public ?EnergyDetails $energy = null {
        get => $this->energy?->energyType !== null ? $this->energy : null;
        set => $this->energy = $value;
    }

    /**
     * All three blocks always exist, like after Doctrine hydration. A null embeddable is persisted
     * as NULL in every one of its columns, which breaks the NOT NULL json columns of PokemonDetails
     * for trainer and energy cards.
     */
    public function __construct()
    {
        $this->pokemon = new PokemonDetails();
        $this->trainer = new TrainerDetails();
        $this->energy = new EnergyDetails();
    }
}
