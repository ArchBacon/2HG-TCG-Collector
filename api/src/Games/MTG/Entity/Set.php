<?php declare(strict_types=1);

namespace App\Games\MTG\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use App\Entity\Traits\TimestampableTrait;
use App\Games\MTG\Enum\SetType;
use App\Games\MTG\Repository\SetRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\Context;
use Symfony\Component\Serializer\Attribute\Groups;
use Symfony\Component\Serializer\Normalizer\DateTimeNormalizer;
use Symfony\Component\Uid\Uuid;

#[ApiResource(
    operations: [new GetCollection(), new Get()],
    routePrefix: '/mtg',
    normalizationContext: ['groups' => ['set:read']],
)]
#[ORM\Entity(repositoryClass: SetRepository::class)]
#[ORM\Table(name: 'mtg_set')]
#[ORM\UniqueConstraint(name: 'uniq_mtg_set_scryfall_id', columns: ['scryfall_id'])]
#[ORM\UniqueConstraint(name: 'uniq_mtg_set_code', columns: ['code'])]
#[ORM\HasLifecycleCallbacks]
class Set
{
    use TimestampableTrait;

    #[Groups(['set:read'])]
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    #[ORM\GeneratedValue(strategy: 'NONE')]
    public private(set) Uuid $id;

    #[ORM\Column(type: 'string', length: 36)]
    public string $scryfallId {
        get => $this->scryfallId;
        set => $this->scryfallId = $value;
    }

    #[Groups(['set:read'])]
    #[ORM\Column(type: 'string', length: 20)]
    public string $code {
        get => $this->code;
        set => $this->code = $value;
    }

    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    public ?string $mtgoCode = null {
        get => $this->mtgoCode;
        set => $this->mtgoCode = $value;
    }

    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    public ?string $arenaCode = null {
        get => $this->arenaCode;
        set => $this->arenaCode = $value;
    }

    #[ORM\Column(nullable: true)]
    public ?int $tcgplayerId = null {
        get => $this->tcgplayerId;
        set => $this->tcgplayerId = $value;
    }

    #[Groups(['set:read'])]
    #[ORM\Column(type: 'string', length: 255)]
    public string $name {
        get => $this->name;
        set => $this->name = $value;
    }

    #[Groups(['set:read'])]
    #[ORM\Column(type: 'string', enumType: SetType::class)]
    public SetType $setType {
        get => $this->setType;
        set => $this->setType = $value;
    }

    #[Groups(['set:read'])]
    #[ORM\Column(type: 'date_immutable', nullable: true)]
    #[Context([DateTimeNormalizer::FORMAT_KEY => 'Y-m-d'])]
    public ?\DateTimeImmutable $releasedAt = null {
        get => $this->releasedAt;
        set => $this->releasedAt = $value;
    }

    #[Groups(['set:read'])]
    #[ORM\Column]
    public int $cardCount {
        get => $this->cardCount;
        set => $this->cardCount = $value;
    }

    #[ORM\Column(nullable: true)]
    public ?int $printedSize = null {
        get => $this->printedSize;
        set => $this->printedSize = $value;
    }

    #[Groups(['set:read'])]
    #[ORM\Column]
    public bool $digital = false {
        get => $this->digital;
        set => $this->digital = $value;
    }

    #[Groups(['set:read'])]
    #[ORM\Column]
    public bool $foilOnly = false {
        get => $this->foilOnly;
        set => $this->foilOnly = $value;
    }

    #[Groups(['set:read'])]
    #[ORM\Column]
    public bool $nonfoilOnly = false {
        get => $this->nonfoilOnly;
        set => $this->nonfoilOnly = $value;
    }

    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    public ?string $blockCode = null {
        get => $this->blockCode;
        set => $this->blockCode = $value;
    }

    #[Groups(['set:read'])]
    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    public ?string $block = null {
        get => $this->block;
        set => $this->block = $value;
    }

    /**
     * The `code` of another Set, e.g. a Commander deck set pointing at its parent expansion.
     * Kept as a plain code rather than a relation since it mirrors Scryfall's own representation
     * and the parent set is not guaranteed to have been imported yet.
     */
    #[Groups(['set:read'])]
    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    public ?string $parentSetCode = null {
        get => $this->parentSetCode;
        set => $this->parentSetCode = $value;
    }

    #[ORM\Column(type: 'string', length: 512)]
    public string $iconSvgUri {
        get => $this->iconSvgUri;
        set => $this->iconSvgUri = $value;
    }

    /** Our own served copy of the icon (see {@see \App\Games\MTG\Service\ScryfallService::syncSetIcons}), not Scryfall's URL. */
    #[Groups(['set:read'])]
    public string $iconUri {
        get => '/mtg/sets/' . $this->code . '.svg';
    }

    public function __construct(string $scryfallId, string $code, string $name, SetType $setType, int $cardCount)
    {
        $this->id = Uuid::v7();
        $this->scryfallId = $scryfallId;
        $this->code = $code;
        $this->name = $name;
        $this->setType = $setType;
        $this->cardCount = $cardCount;
        $this->initializeTimestamps();
    }
}
