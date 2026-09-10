<?php declare(strict_types=1);

namespace App\Games\Lorcana\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use App\Entity\Traits\TimestampableTrait;
use App\Games\Lorcana\Repository\SetRepository;
use DateTimeImmutable;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\Context;
use Symfony\Component\Serializer\Attribute\Groups;
use Symfony\Component\Serializer\Attribute\SerializedName;
use Symfony\Component\Serializer\Normalizer\DateTimeNormalizer;
use Symfony\Component\Uid\Uuid;

#[ApiResource(
    operations: [new GetCollection(), new Get()],
    routePrefix: '/lorcana',
    normalizationContext: ['groups' => ['set:read']],
)]
#[ORM\Entity(repositoryClass: SetRepository::class)]
#[ORM\Table(name: 'lorcana_set')]
#[ORM\UniqueConstraint(name: 'uniq_lorcana_set_set_id', columns: ['set_id'])]
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
     * lorcana-api's own set code, e.g. "TFC" for "The First Chapter". Unlike Scryfall/TCGdex,
     * lorcana-api has no separate short code — this doubles as one, and also prefixes every
     * card's {@see Card::$cardId} within the set.
     */
    #[Groups(['set:read'])]
    #[SerializedName('Set_ID')]
    #[ORM\Column(type: 'string', length: 10)]
    public string $setId {
        get => $this->setId;
        set => $this->setId = $value;
    }

    /** Release order, starting from 1. */
    #[Groups(['set:read'])]
    #[SerializedName('Set_Num')]
    #[ORM\Column]
    public int $setNum {
        get => $this->setNum;
        set => $this->setNum = $value;
    }

    #[Groups(['set:read'])]
    #[SerializedName('Name')]
    #[ORM\Column(type: 'string', length: 255)]
    public string $name {
        get => $this->name;
        set => $this->name = $value;
    }

    #[Groups(['set:read'])]
    #[SerializedName('Release_Date')]
    #[ORM\Column(type: 'date_immutable')]
    #[Context([DateTimeNormalizer::FORMAT_KEY => 'Y-m-d'])]
    public DateTimeImmutable $releasedAt {
        get => $this->releasedAt;
        set => $this->releasedAt = $value;
    }

    /** Total number of cards lorcana-api lists for this set. */
    #[Groups(['set:read'])]
    #[SerializedName('Cards')]
    #[ORM\Column]
    public int $cardCount {
        get => $this->cardCount;
        set => $this->cardCount = $value;
    }

    public function __construct(
        string $setId,
        int $setNum,
        string $name,
        DateTimeImmutable $releasedAt,
        int $cardCount,
    ) {
        $this->id = Uuid::v7();
        $this->setId = $setId;
        $this->setNum = $setNum;
        $this->name = $name;
        $this->releasedAt = $releasedAt;
        $this->cardCount = $cardCount;
        $this->initializeTimestamps();
    }
}
