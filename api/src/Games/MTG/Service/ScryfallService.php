<?php declare(strict_types=1);

namespace App\Games\MTG\Service;

use App\Contract\GameServiceInterface;
use App\Enum\Game;
use App\Enum\IconImportType;
use App\Enum\ImageImportType;
use App\Exception\HttpResponseException;
use App\Games\MTG\Entity\Card;
use App\Games\MTG\Entity\Set;
use App\Games\MTG\Repository\CardRepository;
use App\Games\MTG\Repository\SetRepository;
use App\Repository\ImageJobQueueRepository;
use App\Service\GzipService;
use App\Service\LargeFileDownloadService;
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\Exception\ORMException;
use Indykoning\Jsonl\Jsonl;
use RuntimeException;
use Symfony\Component\DependencyInjection\Attribute\AutoconfigureTag;
use Symfony\Component\Serializer\Normalizer\AbstractNormalizer;
use Symfony\Component\Serializer\SerializerInterface;
use Symfony\Component\Uid\Uuid;
use Symfony\Contracts\HttpClient\Exception\ClientExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\DecodingExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\RedirectionExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\ServerExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface;
use Symfony\Contracts\HttpClient\HttpClientInterface;
use function sprintf;

/**
 * Scryfall API client and MTG data import pipeline, in one place.
 */
#[AutoconfigureTag('api.game_service', ['game' => Game::MagicTheGathering->value])]
final class ScryfallService implements GameServiceInterface
{
    private const Game GAME = Game::MagicTheGathering;
    private const string URL = 'https://api.scryfall.com';
    private const int BATCH_SIZE = 500;

    public function __construct(
        private readonly string $publicDir,
        private readonly HttpClientInterface $http,
        private readonly LargeFileDownloadService $downloadService,
        private readonly SetRepository $setRepository,
        private readonly CardRepository $cardRepository,
        private readonly SerializerInterface $serializer,
        private readonly EntityManagerInterface $entityManager,
        private readonly ImageJobQueueRepository $imageJobQueue,
    ) {}

    /**
     * @throws ORMException
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws HttpResponseException
     */
    public function syncCardInfo(ImageImportType $importType, ?callable $onProgress = null): int
    {
        // Fetch info on bulk data download
        $response = $this->http->request('GET', self::URL . '/bulk-data/all-cards');
        if ($response->getStatusCode() !== 200) {
            throw new HttpResponseException('Could not connect to scryfall API.');
        }

        // Download and unpack .gz bulk data file
        $file = $this->downloadService->download(
            $response->toArray()['jsonl_download_uri'],
            "{$response->toArray()['id']}.jsonl.gz"
        );
        $file = GzipService::unpack($file);
        $fileSize = filesize($file);
        $totalBytes = $fileSize === false ? 0 : $fileSize;

        // Batch import card data
        $imported = 0;
        $cards = [];
        $sets = array_column($this->setRepository->findAll(), 'id', 'code');
        $resource = fopen($file, 'rb');
        if ($resource === false) {
            throw new RuntimeException(sprintf('Could not open downloaded bulk data file "%s".', $file));
        }

        try {
            foreach (Jsonl::decodeFromResource($resource, true) as $card) {
                $cards[] = $card;

                // Import full batch
                if (count($cards) >= self::BATCH_SIZE) {
                    $imported += $this->importCardBatch($cards, $sets, $importType);
                    $cards = [];
                    if ($onProgress !== null) {
                        $onProgress($imported, $this->fileProgress($resource, $totalBytes));
                    }
                }
            }

            // Import remainder
            if (!empty($cards)) {
                $imported += $this->importCardBatch($cards, $sets, $importType);
                if ($onProgress !== null) {
                    $onProgress($imported, 1.0);
                }
            }
        } finally {
            fclose($resource);
            // The import above is already durably committed at this point; a temp file that's
            // already gone (e.g. removed externally) shouldn't turn a successful import into a
            // failure.
            if (is_file($file)) {
                unlink($file);
            }
        }

        return $imported;
    }

    /**
     * Fraction of the decompressed bulk data file read so far, as a rough proxy for how much
     * of the import is done (line count isn't known upfront without a separate full pass).
     *
     * @param resource $resource
     */
    private function fileProgress($resource, int $totalBytes): float
    {
        if ($totalBytes <= 0) {
            return 0.0;
        }

        $position = ftell($resource);
        if ($position === false) {
            return 0.0;
        }

        return min(1.0, $position / $totalBytes);
    }

    /**
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     * @throws HttpResponseException
     */
    public function syncSetInfo(?callable $onProgress = null): int
    {
        /** @var Set[] $sets */
        $sets = array_column($this->setRepository->findAll(), null, 'code');

        $response = $this->http->request('GET', self::URL . '/sets');
        if ($response->getStatusCode() !== 200) {
            throw new HttpResponseException('Could not connect to scryfall API.');
        }

        $syncedSetCount = 0;
        $result = $response->toArray()['data'];
        $total = is_countable($result) ? count($result) : 0;
        foreach ($result as $item) {
            // transform id to scryfall_id so that it won't conflict with internal ids
            $item['scryfall_id'] = $item['id']; unset($item['id']);

            $context = [];
            if (isset($sets[$item['code']])) {
                $context[AbstractNormalizer::OBJECT_TO_POPULATE] = $sets[$item['code']];
            }

            $set = $this->serializer->denormalize($item, Set::class, 'json', $context);
            $this->entityManager->persist($set);
            $syncedSetCount++;
            if ($onProgress !== null) {
                $onProgress($syncedSetCount, $total > 0 ? $syncedSetCount / $total : 1.0);
            }
        }

        $this->entityManager->flush();
        $this->entityManager->clear();

        return $syncedSetCount;
    }

    /**
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws ClientExceptionInterface
     * @throws HttpResponseException
     */
    public function syncSetIcons(IconImportType $importType, ?callable $onProgress = null): int
    {
        $downloaded = 0;
        $sets = $this->setRepository->findAll();
        $total = count($sets);
        $processed = 0;
        foreach ($sets as $set) {
            $processed++;
            $path = $this->publicDir. '/' . self::GAME->value . '/sets/' . $set->code . '.svg';

            if ($importType !== IconImportType::NewOnly || !is_file($path)) {
                $response = $this->http->request('GET', $set->iconSvgUri);
                if ($response->getStatusCode() !== 200) {
                    throw new HttpResponseException('Could not connect to scryfall API.');
                }

                $svg = $response->getContent();
                file_put_contents($path, $svg);
                $downloaded++;
            }

            if ($onProgress !== null) {
                $onProgress($processed, $total > 0 ? $processed / $total : 1.0);
            }
        }

        return $downloaded;
    }

    /**
     * @throws ORMException
     */
    private function importCardBatch(array $cardData, array $sets, ImageImportType $importType): int
    {
        /** @var Card[] $indexedCards */
        $indexedCards = [];
        /** @var Card[] $cards */
        $cards = $this->cardRepository->findByScryfallIds(array_column($cardData, 'id'));
        foreach ($cards as $card) {
            $indexedCards["$card->scryfallId|$card->faceIndex"] = $card;
        }

        /** @var Uuid[] $cardIds */
        $cardIds = [];
        $count = 0;
        foreach ($cardData as $data) {
            $setId = $sets[$data['set']] ?? throw new RuntimeException(sprintf('Unknown set code "%s" for card "%s".', $data['set'], $data['id']));
            $set = $this->entityManager->getReference(Set::class, $setId);
            assert($set instanceof Set);

            // Transform id to scryfall_id to prevent internal id conflict and
            // unset set code as well to prevent internal set reference conflict
            $data['scryfall_id'] = $data['id'];
            unset($data['id'], $data['set']);

            // Get card faces, if any, then unset as there's no entity field for it
            $faces = $data['card_faces'] ?? [];
            unset($data['card_faces']);

            // Upsert card(s) into DB. Cards with multiple faces are separate rows
            if (!isset($data['image_uris']) && count($faces) === 2) {
                $front = $this->upsertCard(array_merge($data, $faces[0]), $set, 0, $indexedCards["{$data['scryfall_id']}|0"] ?? null);
                $back = $this->upsertCard(array_merge($data, $faces[1]), $set, 1, $indexedCards["{$data['scryfall_id']}|1"] ?? null);
                $front->otherFace = $back;
                $back->otherFace = $front;
                $cardIds[] = $front->id;
                $cardIds[] = $back->id;
                $count += 2;
            } else {
                $card = $this->upsertCard($data, $set, 0, $indexedCards["{$data['scryfall_id']}|0"] ?? null);
                $cardIds[] = $card->id;
                $count++;
            }
        }

        // Push to database
        $this->entityManager->flush();
        $this->entityManager->clear();

        // Queue image jobs for downloading images
        if ($importType !== ImageImportType::SkipAll) {
            $this->imageJobQueue->enqueueBatch(self::GAME->value, $cardIds, $importType === ImageImportType::NewOnly);
        }

        // Force garbage collection to prevent memory flooding
        gc_collect_cycles();

        return $count;
    }

    private function upsertCard(array $cardData, Set $set, int $faceIndex, Card|null $card): Card
    {
        // Ensure the Set is set as an argument to properly construct a new Card, if an existing one is not found
        $context = [
            AbstractNormalizer::DEFAULT_CONSTRUCTOR_ARGUMENTS => [
                Card::class => ['set' => $set],
            ],
        ];

        if ($card) {
            $context[AbstractNormalizer::OBJECT_TO_POPULATE] = $card;
        }

        $card = $this->serializer->denormalize($cardData, Card::class, 'json', $context);
        $card->faceIndex = $faceIndex;
        $this->entityManager->persist($card);

        return $card;
    }
}
