<?php declare(strict_types=1);

namespace App\Games\Lorcana\Service;

use App\Contract\CardImageUrlResolverInterface;
use App\Games\Lorcana\Repository\CardRepository;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\Uid\Uuid;

readonly class CardImageUrlResolver implements CardImageUrlResolverInterface
{
    public function __construct(private CardRepository $cardRepository) {}

    public function resolve(string $cardId): ?string
    {
        $card = $this->cardRepository->find(Uuid::fromString($cardId));
        if (!$card) {
            throw new NotFoundHttpException(sprintf('Card "%s" no longer exists.', $cardId));
        }

        return $card->imageUri;
    }
}
