<?php declare(strict_types=1);

namespace App\Games\Pokemon\Service;

use App\Contract\CardImageUrlResolverInterface;
use App\Games\Pokemon\Repository\CardRepository;
use http\Exception\RuntimeException;
use Symfony\Component\Uid\Uuid;

readonly class CardImageUrlResolver implements CardImageUrlResolverInterface
{
    public function __construct(private CardRepository $cardRepository) {}

    public function resolve(string $cardId): ?string
    {
        $card = $this->cardRepository->find(Uuid::fromString($cardId));
        if (!$card) {
            throw new RuntimeException(sprintf('Card "%s" no longer exists.', $cardId));
        }

        return $card->imageUri;
    }
}
