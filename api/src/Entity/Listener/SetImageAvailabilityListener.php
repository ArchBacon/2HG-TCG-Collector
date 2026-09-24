<?php declare(strict_types=1);

namespace App\Entity\Listener;

use App\ApiResource\Set;
use Doctrine\Bundle\DoctrineBundle\Attribute\AsDoctrineListener;
use Doctrine\ORM\Event\PostLoadEventArgs;
use Doctrine\ORM\Events;
use Symfony\Component\DependencyInjection\Attribute\Autowire;

#[AsDoctrineListener(event: Events::postLoad)]
final readonly class SetImageAvailabilityListener
{
    public function __construct(
        #[Autowire('%public_dir%')]
        private string $publicDir,
    ) {}

    public function postLoad(PostLoadEventArgs $args): void
    {
        $set = $args->getObject();
        if (!$set instanceof Set) {
            return;
        }

        $set->availableImages = array_map(
            fn(?string $path) => $path !== null && is_file($this->publicDir . $path),
            $set->imagePaths,
        );
    }
}
