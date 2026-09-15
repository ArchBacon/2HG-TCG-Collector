<?php declare(strict_types=1);

namespace App\Games\DragonBallFusion\Entity;

use ApiPlatform\Doctrine\Orm\Filter\PartialSearchFilter;
use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\QueryParameter;
use App\Entity\Traits\TimestampableTrait;
use App\Games\DragonBallFusion\Enum\Rarity;
use App\Games\DragonBallFusion\Repository\CardRepository;
use App\Games\DragonBallFusion\Enum\Language;
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
    routePrefix: '/dragonballfusion',
    normalizationContext: ['groups' => ['card:read']],
)]
#[ORM\Entity(repositoryClass: CardRepository::class)]
#[ORM\Table(name: 'dragonballfusion_card')]
#[ORM\UniqueConstraint(name: 'uniq_dragonballfusion_card_card_id', columns: ['card_id'])]
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
     * apitcg's own id for this print, e.g. "FB01-001" or "FB01-001-p1" for a parallel art
     * variant — unlike optcgapi/lorcana-api, apitcg already suffixes every distinct print with
     * its own globally unique id, so no separate base-card-id/print-id split is needed here.
     * apitcg duplicates this same value under a `code` key; mapped from `code` rather than `id`
     * only to avoid colliding with this entity's own {@see self::$id}.
     */
    #[Groups(['card:read'])]
    #[SerializedName('code')]
    #[ORM\Column(type: 'string', length: 20)]
    public string $cardId {
        get => $this->cardId;
        set => $this->cardId = $value;
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
    #[SerializedName('name')]
    #[ORM\Column(type: 'string', length: 255)]
    public string $name {
        get => $this->name;
        set => $this->name = $value;
    }

    /** "LEADER", "BATTLE", "EXTRA", or "ENERGY MARKER". */
    #[Groups(['card:read'])]
    #[SerializedName('cardType')]
    #[ORM\Column(type: 'string', length: 30)]
    public string $cardType {
        get => $this->cardType;
        set => $this->cardType = $value;
    }

    /**
     * "Red", "Blue", "Green", "Yellow", "Black", or "ALL" (Energy Marker and some Extra cards
     * have no color of their own). apitcg reports "-" rather than omitting the field for cards
     * this doesn't apply to; the import pipeline normalizes that placeholder to null.
     */
    #[Groups(['card:read'])]
    #[SerializedName('color')]
    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    public ?string $color = null {
        get => $this->color;
        set => $this->color = $value;
    }

    /** Energy cost to play. Null for Leaders and other cards apitcg reports as "-". */
    #[Groups(['card:read'])]
    #[SerializedName('cost')]
    #[ORM\Column(nullable: true)]
    public ?int $cost = null {
        get => $this->cost;
        set => $this->cost = $value;
    }

    /**
     * The specific energy colors required to pay {@see self::$cost}, e.g. "R", "RR", "GGG"
     * (letters = color initials, repeated per pip). Null where apitcg reports "-".
     */
    #[Groups(['card:read'])]
    #[SerializedName('specifiedCost')]
    #[ORM\Column(type: 'string', length: 10, nullable: true)]
    public ?string $specifiedCost = null {
        get => $this->specifiedCost;
        set => $this->specifiedCost = $value;
    }

    /** Battle power. Null for cards apitcg reports as "-" (e.g. most Extra cards). */
    #[Groups(['card:read'])]
    #[SerializedName('power')]
    #[ORM\Column(nullable: true)]
    public ?int $power = null {
        get => $this->power;
        set => $this->power = $value;
    }

    /** Power granted while used as a combo card. Null where apitcg reports "-". */
    #[Groups(['card:read'])]
    #[SerializedName('comboPower')]
    #[ORM\Column(nullable: true)]
    public ?int $comboPower = null {
        get => $this->comboPower;
        set => $this->comboPower = $value;
    }

    /** Card traits/species, slash-separated, e.g. "Saiyan/Universe 7". Null where apitcg reports "-". */
    #[Groups(['card:read'])]
    #[SerializedName('features')]
    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $features = null {
        get => $this->features;
        set => $this->features = $value;
    }

    /** Rules text. Contains literal "<br>" line breaks, as reported by apitcg. */
    #[Groups(['card:read'])]
    #[SerializedName('effect')]
    #[ORM\Column(type: 'text')]
    public string $effect {
        get => $this->effect;
        set => $this->effect = $value;
    }

    /** How the card is obtained, e.g. "BOOSTER PACK -AWAKENED PULSE- [FB01]". */
    #[Groups(['card:read'])]
    #[SerializedName('getIt')]
    #[ORM\Column(type: 'string', length: 255)]
    public string $getIt {
        get => $this->getIt;
        set => $this->getIt = $value;
    }

    /**
     * Null for cards apitcg reports with an empty rarity string (e.g. Energy Marker), not just
     * unset — the import pipeline must normalize "" to null before denormalizing since Rarity
     * has no case for it.
     */
    #[Groups(['card:read'])]
    #[SerializedName('rarity')]
    #[ORM\Column(type: 'string', nullable: true, enumType: Rarity::class)]
    public ?Rarity $rarity = null {
        get => $this->rarity;
        set => $this->rarity = $value;
    }

    /**
     * apitcg's own image asset URL. apitcg reports both a `small` and `large` variant under
     * `images`, but they're identical for every card observed so far — the import pipeline
     * flattens one of them into this field before denormalizing.
     */
    #[SerializedName('imageUri')]
    #[ORM\Column(type: 'string', length: 512, nullable: true)]
    public ?string $imageUri = null {
        get => $this->imageUri;
        set => $this->imageUri = $value;
    }

    /**
     * Our own served copies of this card's image (mirroring
     * {@see \App\Games\Pokemon\Entity\Card::$images} / {@see \App\Games\MTG\Entity\Card::$images}),
     * not apitcg's URL.
     *
     * @var array{small: string, medium: string, large: string}
     */
    #[Groups(['card:read'])]
    public array $images {
        get {
            $filename = $this->id->toRfc4122() . '.webp';

            return [
                'small' => '/dragonballfusion/small/' . $filename,
                'medium' => '/dragonballfusion/medium/' . $filename,
                'large' => '/dragonballfusion/large/' . $filename,
            ];
        }
    }

    public function __construct(
        Set $set,
        string $cardId,
        string $name,
        string $cardType,
        string $effect,
        string $getIt,
    ) {
        $this->id = Uuid::v7();
        $this->set = $set;
        $this->cardId = $cardId;
        $this->name = $name;
        $this->cardType = $cardType;
        $this->effect = $effect;
        $this->getIt = $getIt;
        $this->initializeTimestamps();
    }
}
