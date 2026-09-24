<?php declare(strict_types=1);

namespace App\Games\MTG\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use App\Enum\Game;
use App\Games\MTG\Repository\SetRepository;
use App\Serializer\Attribute\SerializedOrder;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\Groups;

#[ApiResource(
    operations: [new GetCollection(), new Get()],
    routePrefix: '/mtg',
    normalizationContext: ['groups' => ['set:read']],
    cacheHeaders: ['public' => true, 'max_age' => 300, 'shared_max_age' => 3600],
)]
#[ORM\Entity(repositoryClass: SetRepository::class)]
#[ORM\Table(name: 'tcg_mtg_set')]
#[ORM\UniqueConstraint(name: 'uniq_mtg_set_code', columns: ['code'])]
#[SerializedOrder(['id', 'tcg', 'lang', 'code', 'name', 'type', 'block', 'cardCount', 'releasedAt', 'images'])]
class Set extends \App\ApiResource\Set
{
    #[Groups(['set:read'])]
    public Game $tcg {
        get => Game::MagicTheGathering;
    }

    public array $imagePaths {
        get => [
            'icon' => '/' . $this->tcg->value . '/sets/' . $this->code . '.svg',
            'logo' => null,
        ];
    }
}
