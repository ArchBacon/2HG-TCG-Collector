<?php declare(strict_types=1);

namespace App\Games\Pokemon\Entity;

use ApiPlatform\Doctrine\Orm\Filter\PartialSearchFilter;
use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\QueryParameter;
use App\Entity\Traits\TimestampableTrait;
use App\Games\Pokemon\Entity\Embeddable\Legality;
use App\Games\Pokemon\Entity\Embeddable\Variants;
use App\Games\Pokemon\Enum\Category;
use App\Games\Pokemon\Enum\Language;
use App\Games\Pokemon\Repository\CardRepository;
use DateTimeImmutable;
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
    routePrefix: '/pokemon',
    normalizationContext: ['groups' => ['card:read']],
)]
#[ORM\Entity(repositoryClass: CardRepository::class)]
#[ORM\Table(name: 'pokemon_card')]
#[ORM\UniqueConstraint(name: 'uniq_pkm_card_tcgdex_id_lang', columns: ['tcgdex_id', 'lang'])]
#[ORM\Index(name: 'idx_pkm_card_primary_dex_id', columns: ['primary_dex_id'])]
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
     * TCGdex's `id`, e.g. "swsh3-1". Only actually shared across the Western/international
     * locale family (en, fr, de, es, it, ...), which are true translations of the same
     * product sharing one set/numbering scheme. Japanese (and likely Korean/Chinese) is not a
     * translation of that product — it's a structurally different release line with its own
     * set splits and no cross-reference to the international `id` at all (e.g. English's
     * "sv01" has no Japanese counterpart; Japan instead has separate "SV1S"/"SV1V"/...). So
     * `tcgdexId` is only unique *within* a given {@see self::$lang}, never a stable key across
     * languages — there's no reliable way to relate an EN row to its JA "equivalent" via
     * TCGdex's data, and this app doesn't attempt to.
     */
    #[SerializedName('id')]
    #[ORM\Column(type: 'string', length: 40)]
    public string $tcgdexId {
        get => $this->tcgdexId;
        set => $this->tcgdexId = $value;
    }

    #[ORM\Column(type: 'string', enumType: Language::class)]
    public Language $lang {
        get => $this->lang;
        set => $this->lang = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\ManyToOne(targetEntity: Set::class)]
    #[ORM\JoinColumn(name: 'set_id', referencedColumnName: 'id', nullable: false)]
    public Set $set {
        get => $this->set;
        set => $this->set = $value;
    }

    /** Position within the set, e.g. "1", "TG01" — not always numeric, so kept as a string. */
    #[Groups(['card:read'])]
    #[SerializedName('localId')]
    #[ORM\Column(type: 'string', length: 20)]
    public string $localId {
        get => $this->localId;
        set => $this->localId = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 255)]
    public string $name {
        get => $this->name;
        set => $this->name = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', enumType: Category::class)]
    public Category $category {
        get => $this->category;
        set => $this->category = $value;
    }

    /**
     * Free text ("Common", "Holo Rare VMAX", "Illustration Rare", ...) — TCGdex's rarity
     * vocabulary is far larger and looser than Scryfall's, so unlike MTG's Card::$rarity this
     * isn't a fixed enum.
     */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 100, nullable: true)]
    public ?string $rarity = null {
        get => $this->rarity;
        set => $this->rarity = $value;
    }

    /** Missing on some cards, e.g. basic Energy. */
    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $illustrator = null {
        get => $this->illustrator;
        set => $this->illustrator = $value;
    }

    /** TCGdex's own image asset URL (extensionless — a quality/format suffix must be appended). */
    #[SerializedName('image')]
    #[ORM\Column(type: 'string', length: 512, nullable: true)]
    public ?string $imageUri = null {
        get => $this->imageUri;
        set => $this->imageUri = $value;
    }

    /**
     * Our own served copies of this card's image (see {@see \App\Games\Pokemon\Service\ImageJobHandler}
     * and {@see \App\Service\CardImageService}), not TCGdex's URL.
     *
     * @var array{small: string, medium: string, large: string}
     */
    #[Groups(['card:read'])]
    public array $images {
        get {
            $filename = $this->id->toRfc4122() . '.webp';

            return [
                'small' => '/pokemon/small/' . $filename,
                'medium' => '/pokemon/medium/' . $filename,
                'large' => '/pokemon/large/' . $filename,
            ];
        }
    }

    #[Groups(['card:read'])]
    #[ORM\Embedded(class: Variants::class)]
    public Variants $variants {
        get => $this->variants;
        set => $this->variants = $value;
    }

    /**
     * Per-variant marketplace listing ids and pricing snapshots (cardmarket/tcgplayer), keyed
     * by variant type. Kept as raw JSON rather than fixed columns: the sub-keys vary per
     * variant (normal/holofoil/reverse-holofoil/...) and this is a volatile market-data
     * snapshot, not stable card metadata.
     *
     * @var list<array<string, mixed>>|null
     */
    #[ORM\Column(type: 'json', nullable: true)]
    public ?array $variantsDetailed = null {
        get => $this->variantsDetailed;
        set => $this->variantsDetailed = $value;
    }

    /** @var list<int>|null National Pokédex number(s); null for Trainer/Energy cards. */
    #[Groups(['card:read'])]
    #[SerializedName('dexId')]
    #[ORM\Column(type: 'json', nullable: true)]
    public ?array $dexId = null {
        get => $this->dexId;
        set {
            $this->dexId = $value;
            $this->primaryDexId = $value[0] ?? null;
        }
    }

    /**
     * {@see self::$dexId}'s first entry, denormalized into a plain indexed column: MariaDB
     * can't efficiently index values inside a JSON array, and this is what cross-language
     * search (matching an English card's dexId against every other language's cards) actually
     * queries against. Kept in sync automatically whenever dexId is set — never set directly.
     * Multi-species cards (Tag Team/fusion) are only matched by this first dexId.
     *
     * Known gap: Trainer/Energy cards have no dexId at all, so they have no cross-language
     * match of any kind. Not a translation problem to solve later, either — Trainer/Supporter
     * character names are frequently independently renamed by localizers rather than
     * translated (e.g. JA "ナンジャモ" is EN "Iono": unrelated strings), so machine translation
     * wouldn't reliably fix it. Accepted as out of scope for now; a curated character/move-name
     * lookup table would be the actual fix if this becomes a priority.
     */
    #[ORM\Column(nullable: true)]
    public private(set) ?int $primaryDexId = null;

    #[Groups(['card:read'])]
    #[ORM\Column(nullable: true)]
    public ?int $hp = null {
        get => $this->hp;
        set => $this->hp = $value;
    }

    /** @var list<string>|null */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'json', nullable: true)]
    public ?array $types = null {
        get => $this->types;
        set => $this->types = $value;
    }

    #[SerializedName('evolveFrom')]
    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $evolveFrom = null {
        get => $this->evolveFrom;
        set => $this->evolveFrom = $value;
    }

    /** Basic Pokémon flavor text; absent on cards whose face is filled by attacks instead (V/VMAX/...). */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'text', nullable: true)]
    public ?string $description = null {
        get => $this->description;
        set => $this->description = $value;
    }

    /** e.g. "Basic", "Stage1", "Stage2", "VMAX" — open vocabulary, kept as a plain string. */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 30, nullable: true)]
    public ?string $stage = null {
        get => $this->stage;
        set => $this->stage = $value;
    }

    /** e.g. "V", "VMAX", "VSTAR", "GX", "EX". */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    public ?string $suffix = null {
        get => $this->suffix;
        set => $this->suffix = $value;
    }

    /**
     * @var list<array{type: string, name: string, effect?: string}>|null
     */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'json', nullable: true)]
    public ?array $abilities = null {
        get => $this->abilities;
        set => $this->abilities = $value;
    }

    /**
     * `damage` may be non-numeric ("30×", "90+"), so it's kept inside the raw JSON blob rather
     * than a typed column.
     *
     * @var list<array{cost: list<string>, name: string, effect?: string, damage?: int|string}>|null
     */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'json', nullable: true)]
    public ?array $attacks = null {
        get => $this->attacks;
        set => $this->attacks = $value;
    }

    /** @var list<array{type: string, value: string}>|null */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'json', nullable: true)]
    public ?array $weaknesses = null {
        get => $this->weaknesses;
        set => $this->weaknesses = $value;
    }

    /**
     * Not observed on any modern (Sword & Shield era) sample card — the mechanic was dropped
     * for most Pokémon from that era onward — but TCGdex documents the same shape as
     * {@see self::$weaknesses} and older sets are expected to use it.
     *
     * @var list<array{type: string, value: string}>|null
     */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'json', nullable: true)]
    public ?array $resistances = null {
        get => $this->resistances;
        set => $this->resistances = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Column(nullable: true)]
    public ?int $retreat = null {
        get => $this->retreat;
        set => $this->retreat = $value;
    }

    /** Trainer-only: "Item", "Supporter", "Stadium", "Tool", ... */
    #[SerializedName('trainerType')]
    #[ORM\Column(type: 'string', length: 50, nullable: true)]
    public ?string $trainerType = null {
        get => $this->trainerType;
        set => $this->trainerType = $value;
    }

    /** Energy-only: "Basic" or "Special". */
    #[SerializedName('energyType')]
    #[ORM\Column(type: 'string', length: 50, nullable: true)]
    public ?string $energyType = null {
        get => $this->energyType;
        set => $this->energyType = $value;
    }

    /** Rules text for Trainer/Energy cards. */
    #[Groups(['card:read'])]
    #[ORM\Column(type: 'text', nullable: true)]
    public ?string $effect = null {
        get => $this->effect;
        set => $this->effect = $value;
    }

    #[SerializedName('regulationMark')]
    #[ORM\Column(type: 'string', length: 10, nullable: true)]
    public ?string $regulationMark = null {
        get => $this->regulationMark;
        set => $this->regulationMark = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Embedded(class: Legality::class)]
    public Legality $legal {
        get => $this->legal;
        set => $this->legal = $value;
    }

    /** TCGdex's own last-updated timestamp for this card record. */
    #[ORM\Column(nullable: true)]
    public ?DateTimeImmutable $updated = null {
        get => $this->updated;
        set => $this->updated = $value;
    }

    public function __construct(
        Set $set,
        string $tcgdexId,
        Language $lang,
        string $localId,
        string $name,
        Category $category,
    ) {
        $this->id = Uuid::v7();
        $this->set = $set;
        $this->tcgdexId = $tcgdexId;
        $this->lang = $lang;
        $this->localId = $localId;
        $this->name = $name;
        $this->category = $category;
        $this->variants = new Variants();
        $this->legal = new Legality();
        $this->initializeTimestamps();
    }
}
