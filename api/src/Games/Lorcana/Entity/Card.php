<?php declare(strict_types=1);

namespace App\Games\Lorcana\Entity;

use ApiPlatform\Doctrine\Orm\Filter\PartialSearchFilter;
use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\QueryParameter;
use App\Enum\Game;
use App\Games\Lorcana\Repository\CardRepository;
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
    routePrefix: '/lorcana',
    normalizationContext: ['groups' => ['card:read']],
    cacheHeaders: ['public' => true, 'max_age' => 300, 'shared_max_age' => 3600],
)]
#[ORM\Entity(repositoryClass: CardRepository::class)]
#[ORM\Table(name: 'tcg_lorcana_card')]
#[SerializedOrder([
    'id', 'tcg', 'set', 'lang', 'name', 'number', 'rarity', 'typeLine',
    'oracleText', 'flavorText', 'artist', 'faces', 'variants', 'related',
    'images', 'details',
])]
class Card extends \App\ApiResource\Card
{
    #[Groups(['card:read'])]
    public Game $tcg {
        get => Game::Lorcana;
    }

    /** @var array{small: ?string, medium: ?string, large: ?string} */
    #[Groups(['card:read'])]
    public array $images {
        get => [
            'small' => $this->hasImages ? '/' . $this->tcg->value . '/small/' . $this->id->toRfc4122() . '.webp' : null,
            'medium' => $this->hasImages ? '/' . $this->tcg->value . '/medium/' . $this->id->toRfc4122() . '.webp' : null,
            'large' => $this->hasImages ? '/' . $this->tcg->value . '/large/' . $this->id->toRfc4122() . '.webp' : null,
        ];
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
