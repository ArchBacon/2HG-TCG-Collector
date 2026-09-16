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
use App\Service\HttpService;
use App\Service\ProgressReporter;
use App\Service\ZipService;
use App\Service\LanguageService;
use App\Service\LargeFileDownloadService;
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\Exception\ORMException;
use Indykoning\Jsonl\Jsonl;
use JsonException;
use RuntimeException;
use Symfony\Component\DependencyInjection\Attribute\AutoconfigureTag;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\Serializer\Exception\ExceptionInterface;
use Symfony\Component\Serializer\Normalizer\AbstractNormalizer;
use Symfony\Component\Serializer\Normalizer\DenormalizerInterface;
use Symfony\Component\Serializer\SerializerInterface;
use Symfony\Component\Uid\Uuid;
use Symfony\Contracts\HttpClient\Exception\ClientExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\DecodingExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\RedirectionExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\ServerExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface;
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
        #[Autowire('%public_dir%')]
        private readonly string                                    $publicDir,
        private readonly HttpService                               $http,
        private readonly SetRepository                             $setRepository,
        private readonly CardRepository                            $cardRepository,
        private readonly SerializerInterface&DenormalizerInterface $serializer,
        private readonly EntityManagerInterface                    $entityManager,
        private readonly ImageJobQueueRepository                   $imageJobQueue,
        private readonly LanguageService                           $languageService,
        private readonly ZipService                                $zip,
        private readonly LargeFileDownloadService                  $downloadService,
    ) {}

    /**
     * @throws ORMException
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws HttpResponseException
     * @throws JsonException
     * @throws ExceptionInterface
     */
    public function syncCardInfo(ImageImportType $importType, ?callable $onProgress = null): int
    {
        $result = $this->http->json(self::URL . '/bulk-data/all-cards');
        $gzip = $this->downloadService->download($result['jsonl_download_uri'], "{$result['id']}.jsonl.gz");
        $file = $this->zip->unpack($gzip);

        $fileSize = filesize($file);
        $totalBytes = $fileSize === false ? 0 : $fileSize;

        $progress = new ProgressReporter();
        $cards = [];
        $sets = array_column($this->setRepository->findAll(), 'id', 'code');
        $resource = fopen($file, 'rb');
        if ($resource === false) {
            throw new RuntimeException(sprintf('Could not open downloaded bulk data file "%s".', $file));
        }

        try {
            foreach (Jsonl::decodeFromResource($resource, true) as $card) {
                if (!$this->languageService->isSupported($card['lang'])) {
                    continue;
                }

                // Import full batch
                $cards[] = $card;
                if (count($cards) >= self::BATCH_SIZE) {
                    $progress->advance($this->importCardBatch($cards, $sets, $importType));
                    $cards = [];
                    $progress->report($onProgress, fn() => $this->fileProgress($resource, $totalBytes));
                }
            }

            // Import remainder
            if (count($cards) > 0) {
                $progress->advance($this->importCardBatch($cards, $sets, $importType));
                $progress->report($onProgress, fn() => 1.0);
            }
        } finally {
            fclose($resource);
            unlink($file);
        }

        return $progress->count();
    }

    /**
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     * @throws HttpResponseException
     * @throws ExceptionInterface
     */
    public function syncSetInfo(?callable $onProgress = null): int
    {
        /** @var Set[] $sets */
        $sets = array_column($this->setRepository->findAll(), null, 'code');

        $result = $this->http->json(self::URL . '/sets')['data'];
        $progress = new ProgressReporter(count($result));
        foreach ($result as $item) {
            // transform id to scryfall_id so that it won't conflict with internal ids
            $item['scryfall_id'] = $item['id']; unset($item['id']);

            $context = [];
            if (isset($sets[$item['code']])) {
                $context[AbstractNormalizer::OBJECT_TO_POPULATE] = $sets[$item['code']];
            }

            $set = $this->serializer->denormalize($item, Set::class, 'json', $context);
            $this->entityManager->persist($set);
            $progress->advance();
            $progress->report($onProgress);
        }

        $this->entityManager->flush();
        $this->entityManager->clear();

        return $progress->count();
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
        $sets = $this->setRepository->findAll();
        $progress = new ProgressReporter(count($sets));
        foreach ($sets as $set) {
            $path = $this->publicDir. '/' . self::GAME->value . '/sets/' . $set->code . '.svg';

            if ($importType !== IconImportType::NewOnly || !is_file($path)) {
                file_put_contents($path, $this->http->image($set->iconSvgUri));
            }

            $progress->advance();
            $progress->report($onProgress);
        }

        return $progress->count();
    }

    /**
     * @param list<array<string, mixed>> $cardData
     * @param array<string, Uuid> $sets
     * @throws ORMException|ExceptionInterface
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
     * @param array<string, mixed> $cardData
     * @throws ExceptionInterface
     */
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
        /** @noinspection CallableParameterUseCaseInTypeContextInspection */
        $card = $this->serializer->denormalize($cardData, Card::class, 'json', $context);
        $card->faceIndex = $faceIndex;
        $this->entityManager->persist($card);

        return $card;
    }
}
