<?php declare(strict_types=1);

namespace App\Games\MTG\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use App\Enum\Game;
use App\Games\MTG\Repository\CardRepository;
use App\Serializer\Attribute\SerializedOrder;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\Groups;

#[ApiResource(
    operations: [new GetCollection(), new Get()],
    routePrefix: '/mtg',
    normalizationContext: ['groups' => ['card:read']],
)]
#[ORM\Entity(repositoryClass: CardRepository::class)]
#[ORM\Table(name: 'tcg_card_mtg')]
#[SerializedOrder([
    'id', 'tcg', 'set', 'lang', 'name', 'number', 'rarity', 'typeLine',
    'oracleText', 'flavorText', 'artist', 'faces', 'variants', 'related',
    'images', 'details',
])]
final class Card extends \App\ApiResource\Card
{
    #[Groups(['card:read'])]
    public Game $tcg {
        get => Game::MagicTheGathering;
    }

    /** @var null|array{small: string; medium: string; large: string} */
    #[Groups(['card:read'])]
    public ?array $images {
        get => $this->hasImages ? [
            'small' => '/mtg/small/' . $this->id->toRfc4122() . '.webp',
            'medium' => '/mtg/medium/' . $this->id->toRfc4122() . '.webp',
            'large' => '/mtg/large/' . $this->id->toRfc4122() . '.webp',
        ] : null;
    }

    #[Groups(['card:read'])]
    #[ORM\ManyToOne(targetEntity: Set::class)]
    #[ORM\JoinColumn(name: 'set_id', referencedColumnName: 'id', nullable: false)]
    public Set $set {
        get => $this->set;
        set => $this->set = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Embedded(class: CardDetails::class)]
    public CardDetails $details {
        get => $this->details;
        set => $this->details = $value;
    }

    public function __construct(Set $set)
    {
        parent::__construct();
        $this->set = $set;
    }
}
