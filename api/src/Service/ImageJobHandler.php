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
     * @param bool $force Redownload even if every size already exists on disk — needed because
     *        a job being 'pending' doesn't by itself distinguish "never downloaded" from "an
     *        --all-images resync wants this redownloaded regardless of what's already there";
     *        without this, hasAllSizes() would always win and --all-images would silently do
     *        nothing for any card whose files (however stale or corrupt) already exist.
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws ClientExceptionInterface
     */
    public function process(string $cardId, bool $force = false): void
    {
        if (!$force && $this->imageService->hasAllSizes($this->game, $cardId)) {
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
