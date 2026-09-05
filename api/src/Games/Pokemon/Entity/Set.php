<?php declare(strict_types=1);

namespace App\Games\Pokemon\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use App\Entity\Traits\TimestampableTrait;
use App\Games\Pokemon\Entity\Embeddable\CardCount;
use App\Games\Pokemon\Entity\Embeddable\Legality;
use App\Games\Pokemon\Enum\Language;
use App\Games\Pokemon\Repository\SetRepository;
use DateTimeImmutable;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\Context;
use Symfony\Component\Serializer\Attribute\Groups;
use Symfony\Component\Serializer\Attribute\SerializedName;
use Symfony\Component\Serializer\Attribute\SerializedPath;
use Symfony\Component\Serializer\Normalizer\DateTimeNormalizer;
use Symfony\Component\Uid\Uuid;

#[ApiResource(
    operations: [new GetCollection(), new Get()],
    routePrefix: '/pokemon',
    normalizationContext: ['groups' => ['set:read']],
)]
#[ORM\Entity(repositoryClass: SetRepository::class)]
#[ORM\Table(name: 'pokemon_set')]
#[ORM\UniqueConstraint(name: 'uniq_pkm_set_tcgdex_id_lang', columns: ['tcgdex_id', 'lang'])]
#[ORM\HasLifecycleCallbacks]
class Set
{
    use TimestampableTrait;

    #[Groups(['set:read'])]
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    #[ORM\GeneratedValue(strategy: 'NONE')]
    public private(set) Uuid $id;

    /**
     * TCGdex's `id` (e.g. "swsh3"). Unlike Scryfall, TCGdex has no separate short set code —
     * this doubles as one.
     *
     * Only unique *within* a language, not across all of them: TCGdex reuses the same id for
     * genuinely different sets in older eras where JP and international releases were more
     * closely aligned (e.g. "neo1" is a different, smaller set in `ja` than in `en` — 96 cards
     * vs 111) — and separately, MariaDB's default case-insensitive collation means even a pair
     * like `en`'s "xy2" and `ja`'s "XY2" collide as the same value despite being different
     * strings. Mirrors {@see \App\Games\Pokemon\Entity\Card::$tcgdexId}.
     */
    #[Groups(['set:read'])]
    #[SerializedName('id')]
    #[ORM\Column(type: 'string', length: 30)]
    public string $tcgdexId {
        get => $this->tcgdexId;
        set => $this->tcgdexId = $value;
    }

    #[ORM\Column(type: 'string', enumType: Language::class)]
    public Language $lang {
        get => $this->lang;
        set => $this->lang = $value;
    }

    #[Groups(['set:read'])]
    #[ORM\Column(type: 'string', length: 255)]
    public string $name {
        get => $this->name;
        set => $this->name = $value;
    }

    /**
     * The series (`serie`) this set belongs to, e.g. "swsh" / "Sword & Shield". Flattened from
     * TCGdex's nested `serie` object rather than a relation, mirroring how MTG's Set stores its
     * block ({@see \App\Games\MTG\Entity\Set::$blockCode}) as plain columns.
     */
    #[Groups(['set:read'])]
    #[SerializedPath('[serie][id]')]
    #[ORM\Column(type: 'string', length: 30)]
    public string $serieId {
        get => $this->serieId;
        set => $this->serieId = $value;
    }

    #[Groups(['set:read'])]
    #[SerializedPath('[serie][name]')]
    #[ORM\Column(type: 'string', length: 255)]
    public string $serieName {
        get => $this->serieName;
        set => $this->serieName = $value;
    }

    #[Groups(['set:read'])]
    #[SerializedName('releaseDate')]
    #[ORM\Column(type: 'date_immutable')]
    #[Context([DateTimeNormalizer::FORMAT_KEY => 'Y-m-d'])]
    public DateTimeImmutable $releasedAt {
        get => $this->releasedAt;
        set => $this->releasedAt = $value;
    }

    /** Named explicitly since the app-wide camelCase-to-snake_case name converter would
     *  otherwise look for "card_count" — TCGdex's own JSON is camelCase, not snake_case. */
    #[Groups(['set:read'])]
    #[SerializedName('cardCount')]
    #[ORM\Embedded(class: CardCount::class)]
    public CardCount $cardCount {
        get => $this->cardCount;
        set => $this->cardCount = $value;
    }

    #[Groups(['set:read'])]
    #[ORM\Embedded(class: Legality::class)]
    public Legality $legal {
        get => $this->legal;
        set => $this->legal = $value;
    }

    /**
     * Set once every card TCGdex lists for this set (in this language) has been imported —
     * lets a resync skip re-fetching this set's card list and re-diffing it against the DB
     * entirely, since there's nothing left it could find. Reset to false whenever
     * {@see self::$cardCount}'s total changes on a later set-info sync ({@see
     * \App\Games\Pokemon\Service\TCGDex::syncSetInfo()}) — TCGdex does add cards to a set
     * after its initial release (secret rares, later promo waves), and a stale flag must not
     * hide that.
     */
    #[ORM\Column]
    public bool $cardsFullyImported = false {
        get => $this->cardsFullyImported;
        set => $this->cardsFullyImported = $value;
    }

    /** TCGdex's own logo asset URL (extensionless — a format suffix like ".png" must be appended). */
    #[SerializedName('logo')]
    #[ORM\Column(type: 'string', length: 512, nullable: true)]
    public ?string $logoUri = null {
        get => $this->logoUri;
        set => $this->logoUri = $value;
    }

    /** TCGdex's own symbol asset URL (extensionless — a format suffix like ".png" must be appended). */
    #[SerializedName('symbol')]
    #[ORM\Column(type: 'string', length: 512, nullable: true)]
    public ?string $symbolUri = null {
        get => $this->symbolUri;
        set => $this->symbolUri = $value;
    }

    /** Pokémon TCG Online set code, e.g. "DAA". Not every set has one. */
    #[SerializedName('tcgOnline')]
    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    public ?string $tcgOnlineCode = null {
        get => $this->tcgOnlineCode;
        set => $this->tcgOnlineCode = $value;
    }

    /** Not every set has an `abbreviation` object at all, hence nullable. */
    #[SerializedPath('[abbreviation][official]')]
    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    public ?string $officialAbbreviation = null {
        get => $this->officialAbbreviation;
        set => $this->officialAbbreviation = $value;
    }

    #[SerializedPath('[abbreviation][local]')]
    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    public ?string $localAbbreviation = null {
        get => $this->localAbbreviation;
        set => $this->localAbbreviation = $value;
    }

    public function __construct(
        string $tcgdexId,
        Language $lang,
        string $name,
        string $serieId,
        string $serieName,
        DateTimeImmutable $releasedAt,
        CardCount $cardCount,
        Legality $legal,
    ) {
        $this->id = Uuid::v7();
        $this->tcgdexId = $tcgdexId;
        $this->lang = $lang;
        $this->name = $name;
        $this->serieId = $serieId;
        $this->serieName = $serieName;
        $this->releasedAt = $releasedAt;
        $this->cardCount = $cardCount;
        $this->legal = $legal;
        $this->initializeTimestamps();
    }
}
