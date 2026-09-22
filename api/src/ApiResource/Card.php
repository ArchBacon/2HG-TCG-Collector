<?php declare(strict_types=1);

namespace App\ApiResource;

use App\ApiResource\Traits\TimestampableTrait;
use App\Enum\Game;
use App\Enum\Language;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\Groups;
use Symfony\Component\Uid\Uuid;

#[ORM\MappedSuperclass]
#[ORM\HasLifecycleCallbacks]
abstract class Card
{
    use TimestampableTrait;

    public bool $hasImages = false;

    #[Groups(['card:read'])]
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    #[ORM\GeneratedValue(strategy: 'NONE')]
    public protected(set) Uuid $id;

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', enumType: Game::class)]
    abstract public Game $tcg { get; }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 255)]
    public string $name {
        get => $this->name;
        set => $this->name = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', enumType: Language::class)]
    public Language $lang = Language::English {
        get => $this->lang;
        set => $this->lang = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 20)]
    public string $number {
        get => $this->number;
        set => $this->number = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 60, nullable: true)]
    public ?string $rarity = null {
        get => $this->rarity;
        set => $this->rarity = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $artist = null {
        get => $this->artist;
        set => $this->artist = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 255)]
    public string $typeLine {
        get => $this->typeLine;
        set => $this->typeLine = $value;
    }

    /** @var null|array{small: string; medium: string; large: string} */
    #[Groups(['card:read'])]
    abstract public ?array $images { get; }

    /** @var list<string> */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'json')]
    public array $faces = [] {
        get => $this->faces;
        set => $this->faces = $value;
    }

    #[ORM\Column(type: 'smallint')]
    public int $faceIndex = 0 {
        get => $this->faceIndex;
        set => $this->faceIndex = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'text', nullable: true)]
    public ?string $oracleText {
        get => $this->oracleText;
        set => $this->oracleText = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'text', nullable: true)]
    public ?string $flavorText = null {
        get => $this->flavorText;
        set => $this->flavorText = $value;
    }

    // MUST Implement $set in child class
    // no way to enforce this with an abstract field,
    // as the target set is different per game

    /** @var list<string> */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'json')]
    public array $variants = [] {
        get => $this->variants;
        set => $this->variants = $value;
    }

    /** @var list<string> */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'json')]
    public array $related = [] {
        get => $this->related;
        set => $this->related = $value;
    }

    public function __construct()
    {
        $this->id = Uuid::v7();
        $this->initializeTimestamps();
    }
}
