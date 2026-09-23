<?php declare(strict_types=1);

namespace App\Games\DragonBallFusion\Entity;

use ApiPlatform\Doctrine\Orm\Filter\PartialSearchFilter;
use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\QueryParameter;
use App\Enum\Game;
use App\Games\DragonBallFusion\Repository\CardRepository;
use App\Serializer\Attribute\SerializedOrder;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\Groups;

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
#[ORM\Table(name: 'tcg_dragonballfusion_card')]
#[SerializedOrder([
    'id', 'tcg', 'set', 'lang', 'name', 'number', 'rarity', 'typeLine',
    'oracleText', 'flavorText', 'artist', 'faces', 'variants', 'related',
    'images', 'details',
])]
class Card extends \App\ApiResource\Card
{
    #[Groups(['card:read'])]
    public Game $tcg {
        get => Game::DragonBallFusion;
    }

    /** @var null|array{small: string; medium: string; large: string} */
    #[Groups(['card:read'])]
    public ?array $images {
        get => $this->hasImages ? [
            'small' => '/' . $this->tcg->value . '/small/' . $this->id->toRfc4122() . '.webp',
            'medium' => '/' . $this->tcg->value . '/medium/' . $this->id->toRfc4122() . '.webp',
            'large' => '/' . $this->tcg->value . '/large/' . $this->id->toRfc4122() . '.webp',
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
