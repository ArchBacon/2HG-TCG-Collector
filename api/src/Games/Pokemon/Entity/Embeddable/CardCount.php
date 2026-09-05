<?php declare(strict_types=1);

namespace App\Games\Pokemon\Entity\Embeddable;

use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\SerializedName;

#[ORM\Embeddable]
final class CardCount
{
    public function __construct(
        #[ORM\Column]
        public readonly int $total = 0,
        #[ORM\Column]
        public readonly int $official = 0,
        #[ORM\Column]
        public readonly int $holo = 0,
        #[ORM\Column]
        public readonly int $reverse = 0,
        #[ORM\Column]
        public readonly int $normal = 0,
        // Explicit: the app-wide snake_case name converter would otherwise look for
        // "first_ed", but TCGdex's own JSON key is camelCase "firstEd".
        #[SerializedName('firstEd')]
        #[ORM\Column]
        public readonly int $firstEd = 0,
    ) {}
}
