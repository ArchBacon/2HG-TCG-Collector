<?php declare(strict_types=1);

namespace App\Games\MTG\Entity\Embeddable;

use Doctrine\ORM\Mapping as ORM;

#[ORM\Embeddable]
final class ImageUris
{
    public function __construct(
        #[ORM\Column(type: 'string', length: 512, nullable: true)]
        public readonly ?string $small = null,
        #[ORM\Column(type: 'string', length: 512, nullable: true)]
        public readonly ?string $normal = null,
        #[ORM\Column(type: 'string', length: 512, nullable: true)]
        public readonly ?string $large = null,
        #[ORM\Column(type: 'string', length: 512, nullable: true)]
        public readonly ?string $png = null,
        #[ORM\Column(type: 'string', length: 512, nullable: true)]
        public readonly ?string $artCrop = null,
        #[ORM\Column(type: 'string', length: 512, nullable: true)]
        public readonly ?string $borderCrop = null,
        #[ORM\Column(type: 'string', length: 512, nullable: true)]
        public readonly ?string $thumb = null,
        #[ORM\Column(type: 'string', length: 512, nullable: true)]
        public readonly ?string $grid = null,
        #[ORM\Column(type: 'string', length: 512, nullable: true)]
        public readonly ?string $display = null,
        #[ORM\Column(type: 'string', length: 512, nullable: true)]
        public readonly ?string $art = null,
        #[ORM\Column(type: 'string', length: 512, nullable: true)]
        public readonly ?string $crop = null,
    ) {}
}
