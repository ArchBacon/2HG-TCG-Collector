<?php declare(strict_types=1);

namespace App\Games\DragonBallFusion\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use App\Enum\Game;
use App\Games\DragonBallFusion\Repository\SetRepository;
use App\Serializer\Attribute\SerializedOrder;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\Groups;

#[ApiResource(
    operations: [new GetCollection(), new Get()],
    routePrefix: '/dragonballfusion',
    normalizationContext: ['groups' => ['set:read']],
)]
#[ORM\Entity(repositoryClass: SetRepository::class)]
#[ORM\Table(name: 'tcg_dragonballfusion_set')]
#[ORM\UniqueConstraint(name: 'uniq_dragonballfusion_set_code', columns: ['code'])]
#[SerializedOrder(['id', 'tcg', 'code', 'name', 'type', 'block', 'cardCount', 'releasedAt', 'icon'])]
class Set extends \App\ApiResource\Set
{
    #[Groups(['set:read'])]
    public Game $tcg {
        get => Game::DragonBallFusion;
    }

    #[Groups(['set:read'])]
    public ?string $icon {
        get => '/' . $this->tcg->value . '/sets/fallback.webp';
    }
}
