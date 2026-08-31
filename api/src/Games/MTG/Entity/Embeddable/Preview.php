<?php declare(strict_types=1);

namespace App\Games\MTG\Entity\Embeddable;

use Doctrine\ORM\Mapping as ORM;

#[ORM\Embeddable]
final class Preview
{
    public function __construct(
        #[ORM\Column(type: 'date_immutable', nullable: true)]
        public readonly ?\DateTimeImmutable $previewedAt = null,
        #[ORM\Column(type: 'string', length: 255, nullable: true)]
        public readonly ?string $source = null,
        #[ORM\Column(type: 'string', length: 512, nullable: true)]
        public readonly ?string $sourceUri = null,
    ) {}
}
