<?php declare(strict_types=1);

namespace App\Games\MTG\Entity;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\Groups;

#[ORM\Embeddable]
class CardDetails
{
    #[ORM\Column(type: 'string', length: 36)]
    public string $scryfallId {
        get => $this->scryfallId;
        set => $this->scryfallId = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 18)]
    public string $layout {
        get => $this->layout;
        set => $this->layout = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $manaCost = null {
        get => $this->manaCost;
        set => $this->manaCost = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(nullable: true)]
    public ?float $cmc = null {
        get => $this->cmc;
        set => $this->cmc = $value;
    }

    /** @var list<string> WUBRG letters */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'json')]
    public array $colors = [] {
        get => $this->colors;
        set => $this->colors = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    public ?string $power = null {
        get => $this->power;
        set => $this->power = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    public ?string $toughness = null {
        get => $this->toughness;
        set => $this->toughness = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    public ?string $loyalty = null {
        get => $this->loyalty;
        set => $this->loyalty = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'json')]
    public array $legalities = [] {
        get => $this->legalities;
        set => $this->legalities = $value;
    }

    /** @var list<string> e.g. "nonfoil", "foil", "etched" */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'json')]
    public array $finishes = [] {
        get => $this->finishes;
        set => $this->finishes = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column]
    public bool $oversized = false {
        get => $this->oversized;
        set => $this->oversized = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column]
    public bool $promo = false {
        get => $this->promo;
        set => $this->promo = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 6)]
    public string $frame {
        get => $this->frame;
        set => $this->frame = $value;
    }
}
