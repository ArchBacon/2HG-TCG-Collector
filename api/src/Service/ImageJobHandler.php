<?php declare(strict_types=1);

namespace App\Service;

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
        private HttpClientInterface $http,
        private CardImageService $imageService,
    ) {}

    /**
     * @param string $imageUri Source URL to download, captured on the job at enqueue time — no
     *        per-game URL resolution happens here anymore.
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
    public function process(string $cardId, ?string $imageUri, bool $force = false): void
    {
        if (!$force && $this->imageService->hasAllSizes($this->game, $cardId)) {
            return;
        }

        if (!$imageUri) {
            return;
        }

        $data = $this->http->request('GET', $imageUri)->getContent();
        $this->imageService->convertAndSave($data, $this->game, $cardId);
    }
}
