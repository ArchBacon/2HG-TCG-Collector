<?php declare(strict_types=1);

namespace App\Games\Lorcana\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use App\Entity\Traits\TimestampableTrait;
use App\Games\Lorcana\Enum\Rarity;
use App\Games\Lorcana\Repository\CardRepository;
use App\Games\Lorcana\Enum\Language;
use DateTimeImmutable;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\Groups;
use Symfony\Component\Serializer\Attribute\SerializedName;
use Symfony\Component\Uid\Uuid;

#[ApiResource(
    operations: [new GetCollection(), new Get()],
    routePrefix: '/lorcana',
    normalizationContext: ['groups' => ['card:read']],
)]
#[ORM\Entity(repositoryClass: CardRepository::class)]
#[ORM\Table(name: 'lorcana_card')]
#[ORM\UniqueConstraint(name: 'uniq_lorcana_card_unique_id', columns: ['unique_id'])]
#[ORM\HasLifecycleCallbacks]
class Card
{
    use TimestampableTrait;

    #[Groups(['card:read'])]
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    #[ORM\GeneratedValue(strategy: 'NONE')]
    public private(set) Uuid $id;

    /** lorcana-api's own id, e.g. "TFC-115" — its {@see Set::$setId} plus {@see self::$cardNum}. */
    #[SerializedName('Unique_ID')]
    #[ORM\Column(type: 'string', length: 20)]
    public string $uniqueId {
        get => $this->uniqueId;
        set => $this->uniqueId = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\ManyToOne(targetEntity: Set::class)]
    #[ORM\JoinColumn(name: 'set_id', referencedColumnName: 'id', nullable: false)]
    public Set $set {
        get => $this->set;
        set => $this->set = $value;
    }

    #[ORM\Column(type: 'string', enumType: Language::class)]
    public Language $lang = Language::English {
        get => $this->lang;
        set => $this->lang = $value;
    }

    /** Position within the set, starting from 1. */
    #[Groups(['card:read'])]
    #[SerializedName('Card_Num')]
    #[ORM\Column]
    public int $cardNum {
        get => $this->cardNum;
        set => $this->cardNum = $value;
    }

    /** Includes the subtitle, e.g. "Mickey Mouse - Brave Little Tailor". */
    #[Groups(['card:read'])]
    #[SerializedName('Name')]
    #[ORM\Column(type: 'string', length: 255)]
    public string $name {
        get => $this->name;
        set => $this->name = $value;
    }

    /** Includes the subtype where lorcana-api reports one, e.g. "Character", "Action - Song". */
    #[Groups(['card:read'])]
    #[SerializedName('Type')]
    #[ORM\Column(type: 'string', length: 50)]
    public string $type {
        get => $this->type;
        set => $this->type = $value;
    }

    /**
     * Ink color(s). Comma-separated by lorcana-api — most cards have exactly one (e.g.
     * "Amber"), but dual-ink cards list two (e.g. "Amber, Amethyst").
     */
    #[Groups(['card:read'])]
    #[SerializedName('Color')]
    #[ORM\Column(type: 'string', length: 60)]
    public string $color {
        get => $this->color;
        set => $this->color = $value;
    }

    #[Groups(['card:read'])]
    #[SerializedName('Cost')]
    #[ORM\Column]
    public int $cost {
        get => $this->cost;
        set => $this->cost = $value;
    }

    #[Groups(['card:read'])]
    #[SerializedName('Inkable')]
    #[ORM\Column]
    public bool $inkable {
        get => $this->inkable;
        set => $this->inkable = $value;
    }

    #[Groups(['card:read'])]
    #[SerializedName('Rarity')]
    #[ORM\Column(type: 'string', enumType: Rarity::class)]
    public Rarity $rarity {
        get => $this->rarity;
        set => $this->rarity = $value;
    }

    /** Rules text, excluding flavor text. Absent on some vanilla characters. */
    #[Groups(['card:read'])]
    #[SerializedName('Body_Text')]
    #[ORM\Column(type: 'text', nullable: true)]
    public ?string $bodyText = null {
        get => $this->bodyText;
        set => $this->bodyText = $value;
    }

    /** The italicized lore text beneath the body text. Not every card has one. */
    #[Groups(['card:read'])]
    #[SerializedName('Flavor_Text')]
    #[ORM\Column(type: 'text', nullable: true)]
    public ?string $flavorText = null {
        get => $this->flavorText;
        set => $this->flavorText = $value;
    }

    /**
     * Comma-separated by lorcana-api, e.g. "Storyborn, Hero, Queen". Character-only; null for
     * Action/Item/Location cards.
     */
    #[Groups(['card:read'])]
    #[SerializedName('Classifications')]
    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $classifications = null {
        get => $this->classifications;
        set => $this->classifications = $value;
    }

    /**
     * Named keyword abilities, comma-separated by lorcana-api (e.g. "Evasive, Bodyguard").
     * Distinct from {@see self::$bodyText}, which carries the full rules text including any
     * reminder text for these keywords.
     */
    #[Groups(['card:read'])]
    #[SerializedName('Abilities')]
    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $abilities = null {
        get => $this->abilities;
        set => $this->abilities = $value;
    }

    /** Character-only. */
    #[Groups(['card:read'])]
    #[SerializedName('Strength')]
    #[ORM\Column(nullable: true)]
    public ?int $strength = null {
        get => $this->strength;
        set => $this->strength = $value;
    }

    /** Character and Location cards only. */
    #[Groups(['card:read'])]
    #[SerializedName('Willpower')]
    #[ORM\Column(nullable: true)]
    public ?int $willpower = null {
        get => $this->willpower;
        set => $this->willpower = $value;
    }

    /** Lore gained on questing (Character) or simply held (Location). Character/Location-only. */
    #[Groups(['card:read'])]
    #[SerializedName('Lore')]
    #[ORM\Column(nullable: true)]
    public ?int $lore = null {
        get => $this->lore;
        set => $this->lore = $value;
    }

    /**
     * The Disney/Pixar/... property this card's subject is drawn from, e.g. "Encanto". Empty
     * string (not null) when lorcana-api doesn't tag one, mirroring the API's own convention.
     */
    #[Groups(['card:read'])]
    #[SerializedName('Franchise')]
    #[ORM\Column(type: 'string', length: 100, nullable: true)]
    public ?string $franchise = null {
        get => $this->franchise;
        set => $this->franchise = $value;
    }

    #[Groups(['card:read'])]
    #[SerializedName('Artist')]
    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $artist = null {
        get => $this->artist;
        set => $this->artist = $value;
    }

    /** lorcana-api's own last-modified timestamp for this card record. */
    #[SerializedName('Date_Modified')]
    #[ORM\Column(nullable: true)]
    public ?DateTimeImmutable $dateModified = null {
        get => $this->dateModified;
        set => $this->dateModified = $value;
    }

    /** lorcana-api's own image asset URL (full-resolution PNG). */
    #[SerializedName('Image')]
    #[ORM\Column(type: 'string', length: 512, nullable: true)]
    public ?string $imageUri = null {
        get => $this->imageUri;
        set => $this->imageUri = $value;
    }

    /**
     * Our own served copies of this card's image (mirroring
     * {@see \App\Games\Pokemon\Entity\Card::$images} / {@see \App\Games\MTG\Entity\Card::$images}),
     * not lorcana-api's URL.
     *
     * @var array{small: string, normal: string, large: string}
     */
    #[Groups(['card:read'])]
    public array $images {
        get {
            $filename = $this->id->toRfc4122() . '.webp';

            return [
                'small' => '/lorcana/small/' . $filename,
                'normal' => '/lorcana/normal/' . $filename,
                'large' => '/lorcana/large/' . $filename,
            ];
        }
    }

    public function __construct(
        Set $set,
        string $uniqueId,
        int $cardNum,
        string $name,
        string $type,
        string $color,
        int $cost,
        bool $inkable,
        Rarity $rarity,
    ) {
        $this->id = Uuid::v7();
        $this->set = $set;
        $this->uniqueId = $uniqueId;
        $this->cardNum = $cardNum;
        $this->name = $name;
        $this->type = $type;
        $this->color = $color;
        $this->cost = $cost;
        $this->inkable = $inkable;
        $this->rarity = $rarity;
        $this->initializeTimestamps();
    }
}
