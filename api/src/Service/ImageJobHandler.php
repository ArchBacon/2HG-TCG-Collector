<?php declare(strict_types=1);

namespace App\Service;

use App\Contract\CardImageUrlResolverInterface;
use App\Enum\Game;
use Symfony\Contracts\HttpClient\Exception\ClientExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\RedirectionExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\ServerExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface;
use Symfony\Contracts\HttpClient\HttpClientInterface;

final readonly class ImageJobHandler
{
    public function __construct(
        private Game $game,
        private CardImageUrlResolverInterface $urlResolver,
        private HttpClientInterface $http,
        private CardImageService $imageService,
    ) {}

    /**
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws ClientExceptionInterface
     */
    public function process(string $cardId): void
    {
        if ($this->imageService->hasAllSizes($this->game, $cardId)) {
            return;
        }

        $url = $this->urlResolver->resolve($cardId);
        if (!$url) {
            return;
        }

        $data = $this->http->request('GET', $url)->getContent();
        $this->imageService->convertAndSave($data, $this->game, $cardId);
    }
}
