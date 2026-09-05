<?php declare(strict_types=1);

namespace App\Games\Pokemon\Service;

use App\Contract\ImageJobHandlerInterface;
use App\Enum\Game;
use App\Games\Pokemon\Repository\CardRepository;
use App\Service\CardImageService;
use RuntimeException;
use Symfony\Component\DependencyInjection\Attribute\AutoconfigureTag;
use Symfony\Component\Uid\Uuid;
use Symfony\Contracts\HttpClient\HttpClientInterface;

/**
 * Pokémon's implementation of the shared image job contract: downloads a single card's
 * full-resolution PNG from TCGDex and converts it to WebP at every size tier.
 */
#[AutoconfigureTag('api.image_job_handler', ['game' => Game::Pokemon->value])]
final readonly class ImageJobHandler implements ImageJobHandlerInterface
{
    public function __construct(
        private CardRepository $cardRepository,
        private HttpClientInterface $http,
        private CardImageService $imageService,
    ) {}

    public function process(string $cardId): void
    {
        if ($this->imageService->hasAllSizes(Game::Pokemon, $cardId)) {
            return;
        }

        $card = $this->cardRepository->find(Uuid::fromString($cardId));
        if ($card === null) {
            throw new RuntimeException(\sprintf('Card "%s" no longer exists.', $cardId));
        }

        $imageUri = $card->imageUri;
        if ($imageUri === null) {
            return;
        }

        // TCGdex image URLs are extensionless; the highest-quality format suffix must be appended.
        $data = $this->http->request('GET', $imageUri . '/high.webp')->getContent();
        $this->imageService->convertAndSave($data, Game::Pokemon, $cardId);
    }
}
