<?php declare(strict_types=1);

namespace App\Games\DragonBallFusion\Entity\Listener;

use App\Enum\Game;
use App\Games\DragonBallFusion\Entity\Card;
use App\Service\CardImageService;
use Doctrine\Bundle\DoctrineBundle\Attribute\AsEntityListener;
use Doctrine\ORM\Events;

#[AsEntityListener(event: Events::postLoad, method: 'postLoad', entity: Card::class)]
final readonly class CardImageAvailabilityListener
{
    public function __construct(private CardImageService $images) {}

    public function postLoad(Card $card): void
    {
        $card->hasImages = $this->images->hasAllSizes(
            Game::DragonBallFusion,
            $card->id->toRfc4122()
        );
    }
}
