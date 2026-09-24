<?php declare(strict_types=1);

namespace App\Games\Pokemon\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use App\Enum\Game;
use App\Games\Pokemon\Repository\SetRepository;
use Doctrine\ORM\Mapping as ORM;
use App\Serializer\Attribute\SerializedOrder;
use Symfony\Component\Serializer\Attribute\Groups;

#[ApiResource(
    operations: [new GetCollection(), new Get()],
    routePrefix: '/pokemon',
    normalizationContext: ['groups' => ['set:read']],
    cacheHeaders: ['public' => true, 'max_age' => 300, 'shared_max_age' => 3600],
)]
#[ORM\Entity(repositoryClass: SetRepository::class)]
#[ORM\Table(name: 'tcg_pokemon_set')]
#[SerializedOrder(['id', 'tcg', 'lang', 'code', 'name', 'type', 'block', 'cardCount', 'releasedAt', 'images'])]
class Set extends \App\ApiResource\Set
{
    #[Groups(['set:read'])]
    public Game $tcg {
        get => Game::Pokemon;
    }

    public array $imagePaths {
        get => [
            'icon' => '/' . $this->tcg->value . '/sets/icons/' . $this->code . '.webp',
            'logo' => '/' . $this->tcg->value . '/sets/' . $this->code . '.webp',
        ];
    }
}
