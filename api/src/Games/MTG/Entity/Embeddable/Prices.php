<?php declare(strict_types=1);

namespace App\Games\MTG\Entity\Embeddable;

use Doctrine\ORM\Mapping as ORM;

#[ORM\Embeddable]
final class Prices
{
    public function __construct(
        #[ORM\Column(type: 'string', length: 20, nullable: true)]
        public readonly ?string $usd = null,
        #[ORM\Column(type: 'string', length: 20, nullable: true)]
        public readonly ?string $usdFoil = null,
        #[ORM\Column(type: 'string', length: 20, nullable: true)]
        public readonly ?string $usdEtched = null,
        #[ORM\Column(type: 'string', length: 20, nullable: true)]
        public readonly ?string $eur = null,
        #[ORM\Column(type: 'string', length: 20, nullable: true)]
        public readonly ?string $eurFoil = null,
        #[ORM\Column(type: 'string', length: 20, nullable: true)]
        public readonly ?string $tix = null,
    ) {}
}
