<?php declare(strict_types=1);

namespace App\Games\OnePiece\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use App\Enum\Game;
use App\Games\OnePiece\Repository\SetRepository;
use App\Serializer\Attribute\SerializedOrder;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\Groups;

#[ApiResource(
    operations: [new GetCollection(), new Get()],
    routePrefix: '/onepiece',
    normalizationContext: ['groups' => ['set:read']],
    cacheHeaders: ['public' => true, 'max_age' => 300, 'shared_max_age' => 3600],
)]
#[ORM\Entity(repositoryClass: SetRepository::class)]
#[ORM\Table(name: 'tcg_onepiece_set')]
#[ORM\UniqueConstraint(name: 'uniq_onepiece_set_code', columns: ['code'])]
#[SerializedOrder(['id', 'tcg', 'lang', 'code', 'name', 'type', 'block', 'cardCount', 'releasedAt', 'images'])]
class Set extends \App\ApiResource\Set
{
    #[Groups(['set:read'])]
    public Game $tcg {
        get => Game::OnePiece;
    }

    public array $imagePaths {
        get => [
            'icon' => null,
            'logo' => '/' . $this->tcg->value . '/sets/fallback.webp',
        ];
    }
}
