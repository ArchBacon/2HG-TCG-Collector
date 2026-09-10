<?php declare(strict_types=1);

namespace App\Games\MTG\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use App\Entity\Traits\TimestampableTrait;
use App\Games\MTG\Entity\Embeddable\ImageUris;
use App\Games\MTG\Entity\Embeddable\Preview;
use App\Games\MTG\Entity\Embeddable\Prices;
use App\Games\MTG\Enum\BorderColor;
use App\Games\MTG\Enum\CardLayout;
use App\Games\MTG\Enum\Frame;
use App\Games\MTG\Enum\ImageStatus;
use App\Games\MTG\Enum\Language;
use App\Games\MTG\Enum\Rarity;
use App\Games\MTG\Enum\SecurityStamp;
use App\Games\MTG\Repository\CardRepository;
use DateTimeImmutable;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\Context;
use Symfony\Component\Serializer\Attribute\Groups;
use Symfony\Component\Serializer\Normalizer\DateTimeNormalizer;
use Symfony\Component\Uid\Uuid;

#[ApiResource(
    operations: [new GetCollection(), new Get()],
    routePrefix: '/mtg',
    normalizationContext: ['groups' => ['card:read']],
)]
#[ORM\Entity(repositoryClass: CardRepository::class)]
#[ORM\Table(name: 'mtg_card')]
#[ORM\UniqueConstraint(name: 'uniq_mtg_card_scryfall_id_face_index', columns: ['scryfall_id', 'face_index'])]
#[ORM\Index(name: 'idx_mtg_card_oracle_id', columns: ['oracle_id'])]
#[ORM\HasLifecycleCallbacks]
class Card
{
    use TimestampableTrait;

    #[Groups(['card:read'])]
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    #[ORM\GeneratedValue(strategy: 'NONE')]
    public private(set) Uuid $id;

    #[ORM\Column(type: 'string', length: 36)]
    public string $scryfallId {
        get => $this->scryfallId;
        set => $this->scryfallId = $value;
    }

    #[ORM\Column(type: 'string', length: 36, nullable: true)]
    public ?string $oracleId = null {
        get => $this->oracleId;
        set => $this->oracleId = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\ManyToOne(targetEntity: Set::class)]
    #[ORM\JoinColumn(name: 'set_id', referencedColumnName: 'id', nullable: false)]
    public Set $set {
        get => $this->set;
        set => $this->set = $value;
    }

    /**
     * The other face of this same printing (front/back, split halves, adventure halves, ...).
     * Both rows share the same {@see self::$scryfallId}. Null for single-faced cards.
     */
    #[Groups(['card:read'])]
    #[ORM\OneToOne(targetEntity: self::class)]
    #[ORM\JoinColumn(name: 'other_face_id', referencedColumnName: 'id', unique: true, nullable: true)]
    public ?self $otherFace = null {
        get => $this->otherFace;
        set => $this->otherFace = $value;
    }

    /**
     * Which printed face this row represents: 0 for a single-faced card or the front of a
     * double-faced one, 1 for the back. Distinguishes the two rows of a double-faced card
     * (which share {@see self::$scryfallId}) even when both faces happen to share a name.
     */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'smallint', options: ['default' => 0])]
    public int $faceIndex = 0 {
        get => $this->faceIndex;
        set => $this->faceIndex = $value;
    }

    #[ORM\Column(type: 'string', enumType: Language::class)]
    public Language $lang {
        get => $this->lang;
        set => $this->lang = $value;
    }

    #[ORM\Column(type: 'string', enumType: CardLayout::class)]
    public CardLayout $layout {
        get => $this->layout;
        set => $this->layout = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 255)]
    public string $name {
        get => $this->name;
        set => $this->name = $value;
    }

    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $printedName = null {
        get => $this->printedName;
        set => $this->printedName = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $flavorName = null {
        get => $this->flavorName;
        set => $this->flavorName = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $manaCost = null {
        get => $this->manaCost;
        set => $this->manaCost = $value;
    }

    #[ORM\Column(nullable: true)]
    public ?float $cmc = null {
        get => $this->cmc;
        set => $this->cmc = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 255)]
    public string $typeLine = '' {
        get => $this->typeLine;
        set => $this->typeLine = $value;
    }

    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $printedTypeLine = null {
        get => $this->printedTypeLine;
        set => $this->printedTypeLine = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'text', nullable: true)]
    public ?string $oracleText = null {
        get => $this->oracleText;
        set => $this->oracleText = $value;
    }

    #[ORM\Column(type: 'text', nullable: true)]
    public ?string $printedText = null {
        get => $this->printedText;
        set => $this->printedText = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'text', nullable: true)]
    public ?string $flavorText = null {
        get => $this->flavorText;
        set => $this->flavorText = $value;
    }

    /**
     * @var list<string>|null WUBRG letters, null when this row has
     * no colors field of its own (defers to its other face)
     */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'json', nullable: true)]
    public ?array $colors = null {
        get => $this->colors;
        set => $this->colors = $value;
    }

    /** @var list<string> WUBRG letters */
    #[ORM\Column(type: 'json')]
    public array $colorIdentity = [] {
        get => $this->colorIdentity;
        set => $this->colorIdentity = $value;
    }

    /** @var list<string>|null */
    #[ORM\Column(type: 'json', nullable: true)]
    public ?array $colorIndicator = null {
        get => $this->colorIndicator;
        set => $this->colorIndicator = $value;
    }

    /** @var list<string>|null WUBRG + C */
    #[ORM\Column(type: 'json', nullable: true)]
    public ?array $producedMana = null {
        get => $this->producedMana;
        set => $this->producedMana = $value;
    }

    /** @var list<string> */
    #[ORM\Column(type: 'json')]
    public array $keywords = [] {
        get => $this->keywords;
        set => $this->keywords = $value;
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
    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    public ?string $defense = null {
        get => $this->defense;
        set => $this->defense = $value;
    }

    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    public ?string $lifeModifier = null {
        get => $this->lifeModifier;
        set => $this->lifeModifier = $value;
    }

    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    public ?string $handModifier = null {
        get => $this->handModifier;
        set => $this->handModifier = $value;
    }

    /** @var list<int>|null */
    #[ORM\Column(type: 'json', nullable: true)]
    public ?array $attractionLights = null {
        get => $this->attractionLights;
        set => $this->attractionLights = $value;
    }

    /**
     * Format => legality ("legal", "not_legal", "restricted", "banned"). Kept as a raw JSON
     * map rather than fixed columns/enum since Scryfall adds new formats over time.
     *
     * @var array<string, string>
     */
    #[ORM\Column(type: 'json')]
    public array $legalities = [] {
        get => $this->legalities;
        set => $this->legalities = $value;
    }

    /** @var list<int> */
    #[ORM\Column(type: 'json')]
    public array $multiverseIds = [] {
        get => $this->multiverseIds;
        set => $this->multiverseIds = $value;
    }

    #[ORM\Column(nullable: true)]
    public ?int $mtgoId = null {
        get => $this->mtgoId;
        set => $this->mtgoId = $value;
    }

    #[ORM\Column(nullable: true)]
    public ?int $mtgoFoilId = null {
        get => $this->mtgoFoilId;
        set => $this->mtgoFoilId = $value;
    }

    #[ORM\Column(nullable: true)]
    public ?int $arenaId = null {
        get => $this->arenaId;
        set => $this->arenaId = $value;
    }

    #[ORM\Column(nullable: true)]
    public ?int $tcgplayerId = null {
        get => $this->tcgplayerId;
        set => $this->tcgplayerId = $value;
    }

    #[ORM\Column(nullable: true)]
    public ?int $tcgplayerEtchedId = null {
        get => $this->tcgplayerEtchedId;
        set => $this->tcgplayerEtchedId = $value;
    }

    #[ORM\Column(nullable: true)]
    public ?int $cardmarketId = null {
        get => $this->cardmarketId;
        set => $this->cardmarketId = $value;
    }

    /** Undocumented identifier field observed on live Scryfall card objects. */
    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $resourceId = null {
        get => $this->resourceId;
        set => $this->resourceId = $value;
    }

    #[ORM\Embedded(class: ImageUris::class)]
    public ?ImageUris $imageUris = null {
        get => $this->imageUris;
        set => $this->imageUris = $value;
    }

    /**
     * Our own served copies of this card's image (see {@see \App\Games\MTG\Service\ImageJobHandler}
     * and {@see \App\Service\CardImageService}), not Scryfall's URLs.
     *
     * @var array{small: string, medium: string, large: string}
     */
    #[Groups(['card:read'])]
    public array $images {
        get {
            $filename = $this->id->toRfc4122() . '.webp';

            return [
                'small' => '/mtg/small/' . $filename,
                'medium' => '/mtg/medium/' . $filename,
                'large' => '/mtg/large/' . $filename,
            ];
        }
    }

    #[ORM\Column]
    public bool $highresImage = false {
        get => $this->highresImage;
        set => $this->highresImage = $value;
    }

    #[ORM\Column(type: 'string', enumType: ImageStatus::class)]
    public ImageStatus $imageStatus {
        get => $this->imageStatus;
        set => $this->imageStatus = $value;
    }

    #[ORM\Column(nullable: true)]
    public ?DateTimeImmutable $imageUpdatedAt = null {
        get => $this->imageUpdatedAt;
        set => $this->imageUpdatedAt = $value;
    }

    /** @var list<string> e.g. "paper", "arena", "mtgo" */
    #[ORM\Column(type: 'json')]
    public array $games = [] {
        get => $this->games;
        set => $this->games = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column]
    public bool $reserved = false {
        get => $this->reserved;
        set => $this->reserved = $value;
    }

    #[ORM\Column]
    public bool $gameChanger = false {
        get => $this->gameChanger;
        set => $this->gameChanger = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column]
    public bool $foil = false {
        get => $this->foil;
        set => $this->foil = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column]
    public bool $nonfoil = false {
        get => $this->nonfoil;
        set => $this->nonfoil = $value;
    }

    /** @var list<string> e.g. "nonfoil", "foil", "etched" */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'json')]
    public array $finishes = [] {
        get => $this->finishes;
        set => $this->finishes = $value;
    }

    #[ORM\Column]
    public bool $oversized = false {
        get => $this->oversized;
        set => $this->oversized = $value;
    }

    #[ORM\Column]
    public bool $promo = false {
        get => $this->promo;
        set => $this->promo = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column]
    public bool $reprint = false {
        get => $this->reprint;
        set => $this->reprint = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column]
    public bool $variation = false {
        get => $this->variation;
        set => $this->variation = $value;
    }

    #[ORM\Column(type: 'string', length: 36, nullable: true)]
    public ?string $variationOf = null {
        get => $this->variationOf;
        set => $this->variationOf = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 20)]
    public string $collectorNumber = '' {
        get => $this->collectorNumber;
        set => $this->collectorNumber = $value;
    }

    #[ORM\Column]
    public bool $digital = false {
        get => $this->digital;
        set => $this->digital = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', enumType: Rarity::class)]
    public Rarity $rarity {
        get => $this->rarity;
        set => $this->rarity = $value;
    }

    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $watermark = null {
        get => $this->watermark;
        set => $this->watermark = $value;
    }

    #[ORM\Column(type: 'string', length: 36, nullable: true)]
    public ?string $cardBackId = null {
        get => $this->cardBackId;
        set => $this->cardBackId = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $artist = null {
        get => $this->artist;
        set => $this->artist = $value;
    }

    /** @var list<string>|null */
    #[ORM\Column(type: 'json', nullable: true)]
    public ?array $artistIds = null {
        get => $this->artistIds;
        set => $this->artistIds = $value;
    }

    #[ORM\Column(type: 'string', length: 36, nullable: true)]
    public ?string $illustrationId = null {
        get => $this->illustrationId;
        set => $this->illustrationId = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', enumType: BorderColor::class)]
    public BorderColor $borderColor {
        get => $this->borderColor;
        set => $this->borderColor = $value;
    }

    #[ORM\Column(type: 'string', enumType: Frame::class)]
    public Frame $frame {
        get => $this->frame;
        set => $this->frame = $value;
    }

    /** @var list<string>|null open-ended vocabulary (e.g. "legendary", "showcase", "extendedart") */
    #[ORM\Column(type: 'json', nullable: true)]
    public ?array $frameEffects = null {
        get => $this->frameEffects;
        set => $this->frameEffects = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', nullable: true, enumType: SecurityStamp::class)]
    public ?SecurityStamp $securityStamp = null {
        get => $this->securityStamp;
        set => $this->securityStamp = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column]
    public bool $fullArt = false {
        get => $this->fullArt;
        set => $this->fullArt = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column]
    public bool $textless = false {
        get => $this->textless;
        set => $this->textless = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column]
    public bool $booster = false {
        get => $this->booster;
        set => $this->booster = $value;
    }

    #[ORM\Column]
    public bool $storySpotlight = false {
        get => $this->storySpotlight;
        set => $this->storySpotlight = $value;
    }

    /** @var list<string>|null open-ended vocabulary (e.g. "universesbeyond", "playtest") */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'json', nullable: true)]
    public ?array $promoTypes = null {
        get => $this->promoTypes;
        set => $this->promoTypes = $value;
    }

    #[ORM\Column(nullable: true)]
    public ?bool $contentWarning = null {
        get => $this->contentWarning;
        set => $this->contentWarning = $value;
    }

    #[ORM\Column(nullable: true)]
    public ?int $edhrecRank = null {
        get => $this->edhrecRank;
        set => $this->edhrecRank = $value;
    }

    #[ORM\Column(nullable: true)]
    public ?int $pennyRank = null {
        get => $this->pennyRank;
        set => $this->pennyRank = $value;
    }

    #[ORM\Embedded(class: Preview::class)]
    public ?Preview $preview = null {
        get => $this->preview;
        set => $this->preview = $value;
    }

    #[ORM\Embedded(class: Prices::class)]
    public Prices $prices {
        get => $this->prices;
        set => $this->prices = $value;
    }

    /** @var array<string, string> */
    #[ORM\Column(type: 'json')]
    public array $relatedUris = [] {
        get => $this->relatedUris;
        set => $this->relatedUris = $value;
    }

    /** @var array<string, string> */
    #[ORM\Column(type: 'json')]
    public array $purchaseUris = [] {
        get => $this->purchaseUris;
        set => $this->purchaseUris = $value;
    }

    /**
     * Tokens, meld parts/results, and other cards this one references.
     *
     * @var list<array{id: string, component: string, name: string, typeLine: string, uri: string}>|null
     */
    #[ORM\Column(type: 'json', nullable: true)]
    public ?array $allParts = null {
        get => $this->allParts;
        set => $this->allParts = $value;
    }

    /** Human-facing Scryfall page for this card, kept since it embeds a non-derivable name slug. */
    #[ORM\Column(type: 'string', length: 512)]
    public string $scryfallUri = '' {
        get => $this->scryfallUri;
        set => $this->scryfallUri = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'date_immutable')]
    #[Context([DateTimeNormalizer::FORMAT_KEY => 'Y-m-d'])]
    public DateTimeImmutable $releasedAt {
        get => $this->releasedAt;
        set => $this->releasedAt = $value;
    }

    public function __construct(Set $set, string $scryfallId, Language $lang, CardLayout $layout, string $name)
    {
        $this->id = Uuid::v7();
        $this->set = $set;
        $this->scryfallId = $scryfallId;
        $this->lang = $lang;
        $this->layout = $layout;
        $this->name = $name;
        $this->imageStatus = ImageStatus::Missing;
        $this->rarity = Rarity::Common;
        $this->borderColor = BorderColor::Black;
        $this->frame = Frame::Frame2015;
        $this->prices = new Prices();
        $this->releasedAt = new DateTimeImmutable();
        $this->initializeTimestamps();
    }
}
