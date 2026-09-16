<?php declare(strict_types=1);

namespace App\Games\Pokemon\Service;

use App\Contract\CardImageUrlResolverInterface;
use App\Games\Pokemon\Repository\CardRepository;
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

        // Card::$imageUri is TCGdex's asset URL with no quality/format suffix — the API 200s on
        // the bare URL too, but with an HTML stub page instead of image bytes, which is exactly
        // what was silently breaking every real (non-cached) image download.
        return $card->imageUri ? $card->imageUri . '/high.webp' : null;
    }
}
