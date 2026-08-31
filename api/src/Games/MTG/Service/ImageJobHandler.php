<?php declare(strict_types=1);

namespace App\Games\MTG\Service;

use App\Contract\ImageJobHandlerInterface;
use App\Enum\Game;
use App\Games\MTG\Repository\CardRepository;
use App\Service\CardImageService;
use RuntimeException;
use Symfony\Component\DependencyInjection\Attribute\AutoconfigureTag;
use Symfony\Component\Uid\Uuid;
use Symfony\Contracts\HttpClient\HttpClientInterface;

/**
 * MTG's implementation of the shared image job contract: downloads a single card's
 * full-resolution PNG from Scryfall and converts it to WebP at every size tier.
 */
#[AutoconfigureTag('api.image_job_handler', ['game' => Game::MagicTheGathering->value])]
final readonly class ImageJobHandler implements ImageJobHandlerInterface
{
    public function __construct(
        private CardRepository $cardRepository,
        private HttpClientInterface $http,
        private CardImageService $imageService,
    ) {}

    public function process(string $cardId): void
    {
        if ($this->imageService->hasAllSizes(Game::MagicTheGathering, $cardId)) {
            return;
        }

        $card = $this->cardRepository->find(Uuid::fromString($cardId));
        if ($card === null) {
            throw new RuntimeException(\sprintf('Card "%s" no longer exists.', $cardId));
        }

        $png = $card->imageUris?->png;
        if ($png === null) {
            return;
        }

        $data = $this->http->request('GET', $png)->getContent();
        $this->imageService->convertAndSave($data, Game::MagicTheGathering, $cardId);
    }
}
