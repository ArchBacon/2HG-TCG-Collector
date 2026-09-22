<?php declare(strict_types=1);

namespace App\Games\MTG\Service;

use App\Contract\ImportServiceInterface;
use App\Enum\Game;
use App\Enum\IconImportType;
use App\Enum\ImageImportType;
use App\Games\MTG\Entity\Card;
use App\Games\MTG\Entity\Set;
use App\Games\MTG\Repository\CardRepository;
use App\Games\MTG\Repository\SetRepository;
use App\Repository\ImageJobQueueRepository;
use App\Service\HttpService;
use App\Service\LanguageService;
use App\Service\ProgressReporter;
use App\Service\ZipService;
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\Exception\ORMException;
use Indykoning\Jsonl\Jsonl;
use RuntimeException;
use Symfony\Component\DependencyInjection\Attribute\AutoconfigureTag;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\Serializer\Exception\ExceptionInterface;
use Symfony\Component\Serializer\Normalizer\AbstractNormalizer;
use Symfony\Component\Serializer\Normalizer\DenormalizerInterface;
use Symfony\Component\Serializer\SerializerInterface;
use Symfony\Contracts\HttpClient\Exception\ClientExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\DecodingExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\RedirectionExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\ServerExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface;

#[AutoconfigureTag('api.game_service', ['game' => Game::MagicTheGathering->value])]
final class ScryfallImportService implements ImportServiceInterface
{
    private const Game GAME = Game::MagicTheGathering;
    private const string URL = 'https://api.scryfall.com';

    public function __construct(
        #[Autowire('%public_dir%')]
        private readonly string $publicDir,
        private readonly HttpService $http,
        private readonly SetRepository $setRepository,
        private readonly CardRepository $cardRepository,
        private readonly SerializerInterface&DenormalizerInterface $serializer,
        private readonly EntityManagerInterface $entityManager,
        private readonly ZipService $zip,
        private readonly LanguageService $language,
        private readonly ImageJobQueueRepository $imageJobs,
        private readonly ScryfallCardFaceExtractor $faceExtractor,
    ) {}

    public function prepare(): void {}
    public function finalize(): void {}

    /**
     * @inheritDoc
     *
     * @throws ExceptionInterface
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     */
    public function importSets(IconImportType $importType, ?callable $onProgress = null): void
    {
        $sets = array_column($this->setRepository->findAll(), null, 'code');
        $result = $this->http->json(self::URL . '/sets')['data'];
        $progress = new ProgressReporter(count($result));

        foreach ($result as $item) {
            $item['type'] = $item['set_type'];
            $item['block'] = $item['block_code'] ?? $item['code'];

            $set = $this->serializer->denormalize($item, Set::class, 'json', [
                AbstractNormalizer::OBJECT_TO_POPULATE => $sets[$item['code']] ?? null,
                AbstractNormalizer::IGNORED_ATTRIBUTES => ['id'],
            ]);
            $this->entityManager->persist($set);

            // Import set icon
            $path = $this->publicDir. '/' . self::GAME->value . '/sets/' . $set->code . '.svg';
            if ($importType !== IconImportType::NewOnly || !is_file($path)) {
                file_put_contents($path, $this->http->image($item['icon_svg_uri']));
            }

            $progress->advance();
            $progress->report($onProgress);
        }

        $this->entityManager->flush();
        $this->entityManager->clear();
    }

    /**
     * @throws ORMException
     * @throws ExceptionInterface
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     */
    public function importCards(ImageImportType $importType, ?callable $onProgress = null): void
    {
        $result = $this->http->json(self::URL . '/bulk-data/all-cards');
        $zip = $this->http->download($result['jsonl_download_uri'], "{$result['id']}.jsonl.gz");
        $file = $this->zip->unpack($zip);
        $fileSize = filesize($file);

        $progress = new ProgressReporter();
        $sets = array_column($this->setRepository->findAll(), 'id', 'code');

        $resource = fopen($file, 'rb');
        if ($resource === false) {
            throw new RuntimeException(sprintf('Could not open downloaded bulk data file "%s".', $file));
        }

        // Fraction is driven by bytes read (the generator has always consumed up to the current
        // file position by the time we see an item), independent of $progress's own count, which
        // tracks imported cards instead — unsupported-language rows are skipped but still move
        // the byte position, so reporting it here keeps the percentage moving on every row.
        $fraction = static fn (): float => ftell($resource) / $fileSize;

        // Card id (RFC 4122 string) => source image URL, accumulated between flushes and handed
        // to enqueueBatch() below — mirroring every other game's importer — rather than each row
        // upserting its own ImageJobQueue row through the ORM.
        $cardImageUris = [];

        try {
            foreach (Jsonl::decodeFromResource($resource, true) as $item) {
                if (!$this->language->isSupported($item['lang'])) {
                    $progress->report($onProgress, $fraction);
                    continue;
                }

                $this->importCardRow($item, $sets, $cardImageUris);
                $progress->advance();
                $progress->report($onProgress, $fraction);

                if ($progress->count() % 200 === 0) {
                    $this->entityManager->flush();
                    $this->entityManager->clear();
                    $this->enqueueImages($importType, $cardImageUris);
                    $cardImageUris = [];
                    gc_collect_cycles();
                }
            }

            // flush any remaining persisted cards
            $this->entityManager->flush();
            $this->entityManager->clear();
            $this->enqueueImages($importType, $cardImageUris);
        } finally {
            fclose($resource);
            unlink($file);
        }
    }

    /**
     * @param array<string, ?string> $cardImageUris card id (RFC 4122 string) => image URL
     */
    private function enqueueImages(ImageImportType $importType, array $cardImageUris): void
    {
        if ($importType === ImageImportType::SkipAll) {
            return;
        }

        $this->imageJobs->enqueueBatch(self::GAME->value, $cardImageUris, $importType === ImageImportType::NewOnly);
    }

    /**
     * @param array<string, int> $sets set id by set code
     * @param array<string, ?string> $cardImageUris card id (RFC 4122 string) => image URL,
     *        appended to in place
     *
     * @throws ORMException
     * @throws ExceptionInterface
     */
    private function importCardRow(array $item, array $sets, array &$cardImageUris): void
    {
        $setId = $sets[$item['set']] ?? throw new RuntimeException(sprintf('Unknown set code "%s" for card "%s".', $item['set'], $item['id']));
        $set = $this->entityManager->getReference(Set::class, $setId);
        assert($set instanceof Set);

        $relatedTargets = $this->cardRepository->findByScryfallIds($this->faceExtractor->extractRelatedScryfallIds($item));
        $variantTargets = $this->cardRepository->findByScryfallIds($this->faceExtractor->extractVariantScryfallIds($item));
        $existingFaces = array_column($this->cardRepository->findByScryfallIds([$item['id']]), null, 'faceIndex');

        /** @var list<Card> $cardFaces */
        $cardFaces = [];
        $faces = $this->faceExtractor->extractFaces($item, array_column($relatedTargets, 'id'), array_column($variantTargets, 'id'));
        foreach ($faces as $key => $face) {
            $face['number'] = $face['collector_number'];

            $card = $this->serializer->denormalize($face, Card::class, 'json', [
                AbstractNormalizer::OBJECT_TO_POPULATE => $existingFaces[$key] ?? null,
                AbstractNormalizer::IGNORED_ATTRIBUTES => ['id', 'set'],
                AbstractNormalizer::DEFAULT_CONSTRUCTOR_ARGUMENTS => [
                    Card::class => ['set' => $set],
                ],
            ]);
            $card->faceIndex = $key;
            $cardFaces[] = $card;

            $cardImageUris[$card->id->toRfc4122()] = $face['image_uri'];
        }

        $cardIds = array_column($cardFaces, 'id');
        foreach ($cardFaces as $face) {
            $face->faces = $cardIds;
            $this->entityManager->persist($face);
        }

        $this->linkReciprocalCards($relatedTargets, $variantTargets, $cardIds);
    }

    /**
     * A related/variant target imported earlier had no way to reference this card back, since
     * it didn't exist yet - backfill the reverse side now that it does. $relatedTargets and
     * $variantTargets are already Doctrine-managed entities, so mutating them here is enough;
     * Doctrine picks up the change without an explicit persist().
     *
     * @param list<Card> $relatedTargets
     * @param list<Card> $variantTargets
     * @param list<string> $cardIds
     */
    private function linkReciprocalCards(array $relatedTargets, array $variantTargets, array $cardIds): void
    {
        foreach ($relatedTargets as $target) {
            $target->related = array_values(array_unique([...$target->related, ...$cardIds]));
        }
        foreach ($variantTargets as $target) {
            $target->variants = array_values(array_unique([...$target->variants, ...$cardIds]));
        }
    }
}
