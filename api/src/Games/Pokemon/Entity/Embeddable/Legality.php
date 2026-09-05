<?php declare(strict_types=1);

namespace App\Games\Pokemon\Entity\Embeddable;

use Doctrine\ORM\Mapping as ORM;

#[ORM\Embeddable]
final class Legality
{
    public function __construct(
        #[ORM\Column]
        public readonly bool $standard = false,
        #[ORM\Column]
        public readonly bool $expanded = false,
    ) {}
}
