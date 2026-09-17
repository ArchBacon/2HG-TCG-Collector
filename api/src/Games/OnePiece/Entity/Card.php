<?php declare(strict_types=1);

namespace App\Games\OnePiece\Entity;

use ApiPlatform\Doctrine\Orm\Filter\PartialSearchFilter;
use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\QueryParameter;
use App\ApiResource\Traits\TimestampableTrait;
use App\Games\OnePiece\Enum\Language;
use App\Games\OnePiece\Enum\Rarity;
use App\Games\OnePiece\Repository\CardRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\Groups;
use Symfony\Component\Serializer\Attribute\SerializedName;
use Symfony\Component\Uid\Uuid;

#[ApiResource(
    operations: [
        new GetCollection(parameters: [
            'name' => new QueryParameter(filter: new PartialSearchFilter(), property: 'name'),
        ]),
        new Get(),
    ],
    routePrefix: '/onepiece',
    normalizationContext: ['groups' => ['card:read']],
)]
#[ORM\Entity(repositoryClass: CardRepository::class)]
#[ORM\Table(name: 'onepiece_card')]
#[ORM\UniqueConstraint(name: 'uniq_onepiece_card_set_print_image', columns: ['set_id', 'print_id', 'image_uri'])]
#[ORM\HasLifecycleCallbacks]
class Card
{
    use TimestampableTrait;

    #[Groups(['card:read'])]
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    #[ORM\GeneratedValue(strategy: 'NONE')]
    public private(set) Uuid $id;

    /**
     * optcgapi's card number within the set, e.g. "OP07-015". Not unique on its own — every
     * art variant of a card (parallel, manga, ...) shares the same card_set_id and is only
     * distinguished by {@see self::$printId}.
     */
    #[SerializedName('card_set_id')]
    #[ORM\Column(type: 'string', length: 20)]
    public string $cardId {
        get => $this->cardId;
        set => $this->cardId = $value;
    }

    /**
     * optcgapi's own id for this specific print, e.g. "OP07-015" for the regular version or
     * "OP07-015_p1" for its parallel art, unlike {@see self::$cardId} which multiple art
     * variants of the same card share. Neither globally unique (optcgapi reuses suffixed ids
     * across sets) nor unique within its own {@see self::$set} (optcgapi sometimes fails to
     * suffix a genuinely distinct print, e.g. a parallel/alt-art sharing its base card's id) —
     * {@see self::$imageUri} is the only field that reliably differs between such prints, so the
     * actual uniqueness constraint is on (set, printId, imageUri) together.
     */
    #[Groups(['card:read'])]
    #[SerializedName('card_image_id')]
    #[ORM\Column(type: 'string', length: 20)]
    public string $printId {
        get => $this->printId;
        set => $this->printId = $value;
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

    #[Groups(['card:read'])]
    #[SerializedName('card_name')]
    #[ORM\Column(type: 'string', length: 255)]
    public string $name {
        get => $this->name;
        set => $this->name = $value;
    }

    /** "Leader", "Character", "Event", or "Stage". */
    #[Groups(['card:read'])]
    #[SerializedName('card_type')]
    #[ORM\Column(type: 'string', length: 20)]
    public string $type {
        get => $this->type;
        set => $this->type = $value;
    }

    #[Groups(['card:read'])]
    #[SerializedName('card_color')]
    #[ORM\Column(type: 'string', length: 30)]
    public string $color {
        get => $this->color;
        set => $this->color = $value;
    }

    /** DON!! cost to play. Null for Leaders, which have no play cost. */
    #[Groups(['card:read'])]
    #[SerializedName('card_cost')]
    #[ORM\Column(nullable: true)]
    public ?int $cost = null {
        get => $this->cost;
        set => $this->cost = $value;
    }

    /** Battle power. Null for Events and Stages, which don't have one. */
    #[Groups(['card:read'])]
    #[SerializedName('card_power')]
    #[ORM\Column(nullable: true)]
    public ?int $power = null {
        get => $this->power;
        set => $this->power = $value;
    }

    /** Starting life total. Leader-only; null for every other card type. */
    #[Groups(['card:read'])]
    #[SerializedName('life')]
    #[ORM\Column(nullable: true)]
    public ?int $life = null {
        get => $this->life;
        set => $this->life = $value;
    }

    /** Counter power this card can add when used as a blocker. Character-only. */
    #[Groups(['card:read'])]
    #[SerializedName('counter_amount')]
    #[ORM\Column(nullable: true)]
    public ?int $counterAmount = null {
        get => $this->counterAmount;
        set => $this->counterAmount = $value;
    }

    /**
     * Combat attribute, e.g. "Slash", "Strike", "Ranged", "Special", "Wisdom". Not every card has
     * one. Widened past what a real attribute needs — optcgapi has at least one row where this
     * duplicates {@see self::$subTypes} instead of a real attribute value.
     */
    #[Groups(['card:read'])]
    #[SerializedName('attribute')]
    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $attribute = null {
        get => $this->attribute;
        set => $this->attribute = $value;
    }

    /** Traits, e.g. "Straw Hat Crew/Animal". Comma/slash-separated by optcgapi. */
    #[Groups(['card:read'])]
    #[SerializedName('sub_types')]
    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $subTypes = null {
        get => $this->subTypes;
        set => $this->subTypes = $value;
    }

    /** Rules text. */
    #[Groups(['card:read'])]
    #[SerializedName('card_text')]
    #[ORM\Column(type: 'text', nullable: true)]
    public ?string $text = null {
        get => $this->text;
        set => $this->text = $value;
    }

    #[Groups(['card:read'])]
    #[SerializedName('rarity')]
    #[ORM\Column(type: 'string', enumType: Rarity::class)]
    public Rarity $rarity {
        get => $this->rarity;
        set => $this->rarity = $value;
    }

    /** optcgapi's own image asset URL. Part of this card's uniqueness key, see {@see self::$printId}. */
    #[SerializedName('card_image')]
    #[ORM\Column(type: 'string', length: 512, nullable: true)]
    public ?string $imageUri = null {
        get => $this->imageUri;
        set => $this->imageUri = $value;
    }

    /**
     * Our own served copies of this card's image (mirroring
     * {@see \App\Games\Pokemon\Entity\Card::$images} / {@see \App\Games\MTG\Entity\CardV1::$images}),
     * not optcgapi's URL.
     *
     * @var array{small: string, medium: string, large: string}
     */
    #[Groups(['card:read'])]
    public array $images {
        get {
            $filename = $this->id->toRfc4122() . '.webp';

            return [
                'small' => '/onepiece/small/' . $filename,
                'medium' => '/onepiece/medium/' . $filename,
                'large' => '/onepiece/large/' . $filename,
            ];
        }
    }

    public function __construct(
        Set    $set,
        string $cardId,
        string $printId,
        string $name,
        string $type,
        string $color,
        Rarity $rarity,
    ) {
        $this->id = Uuid::v7();
        $this->set = $set;
        $this->cardId = $cardId;
        $this->printId = $printId;
        $this->name = $name;
        $this->type = $type;
        $this->color = $color;
        $this->rarity = $rarity;
        $this->initializeTimestamps();
    }
}
