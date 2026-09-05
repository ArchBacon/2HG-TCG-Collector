<?php declare(strict_types=1);

namespace App\Games\Pokemon\Entity\Embeddable;

use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\SerializedName;

/** Which print variants exist for this specific card (not which ones the collector owns). */
#[ORM\Embeddable]
final class Variants
{
    public function __construct(
        #[ORM\Column]
        public readonly bool $normal = false,
        #[ORM\Column]
        public readonly bool $reverse = false,
        #[ORM\Column]
        public readonly bool $holo = false,
        // Both explicit: the app-wide snake_case name converter would otherwise look for
        // "first_edition"/"w_promo", but TCGdex's own JSON keys are camelCase.
        #[SerializedName('firstEdition')]
        #[ORM\Column]
        public readonly bool $firstEdition = false,
        #[SerializedName('wPromo')]
        #[ORM\Column]
        public readonly bool $wPromo = false,
    ) {}
}
