<?php declare(strict_types=1);

namespace App\Games\MTG\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use App\Enum\Game;
use App\Games\MTG\Repository\SetRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\Groups;

#[ApiResource(
    operations: [new GetCollection(), new Get()],
    routePrefix: '/mtg',
    normalizationContext: ['groups' => ['set:read']],
)]
#[ORM\Entity(repositoryClass: SetRepository::class)]
#[ORM\Table(name: 'tcg_set_mtg')]
#[ORM\UniqueConstraint(name: 'uniq_mtg_set_code', columns: ['code'])]
class Set extends \App\ApiResource\Set
{
    #[Groups(['set:read'])]
    public Game $tcg {
        get => Game::MagicTheGathering;
    }

    #[Groups(['set:read'])]
    public ?string $icon {
        get => '/mtg/sets/' . $this->code . '.svg';
    }
}
