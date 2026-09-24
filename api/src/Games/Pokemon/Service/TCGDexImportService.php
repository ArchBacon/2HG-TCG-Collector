<?php declare(strict_types=1);

namespace App\Games\Pokemon\Service;

use App\Contract\ImportServiceInterface;
use App\Enum\Game;
use App\Enum\IconImportType;
use App\Enum\ImageImportType;
use App\Exception\HttpResponseException;
use App\Games\Pokemon\Entity\Card;
use App\Games\Pokemon\Entity\Set;
use App\Games\Pokemon\Repository\CardRepository;
use App\Games\Pokemon\Repository\SetRepository;
use App\Repository\ImageJobQueueRepository;
use App\Service\HttpService;
use App\Service\LanguageService;
use App\Service\ProgressReporter;
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\Exception\ORMException;
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

/** TCGDex API client and Pokémon data import pipeline. */
#[AutoconfigureTag('api.game_service', ['game' => Game::Pokemon->value])]
class TCGDexImportService implements ImportServiceInterface
{
    private const Game GAME = Game::Pokemon;
    private const string URL = 'https://api.tcgdex.net/v2';

    private int $totalSets = 0;
    private int $totalCards = 0;

    public function __construct(
        #[Autowire('%public_dir%')]
        private readonly string $publicDir,
        private readonly HttpService $http,
        private readonly SetRepository $setRepository,
        private readonly CardRepository $cardRepository,
        private readonly ImageJobQueueRepository $imageJobQueue,
        private readonly SerializerInterface&DenormalizerInterface $serializer,
        private readonly EntityManagerInterface $entityManager,
        private readonly LanguageService $language,
        private readonly TCGDexDataTransformer $transformer,
    ) {}

    /**
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     */
    public function prepare(): void
    {
        foreach ($this->language->getSupportedLanguages() as $lang) {
            $result = $this->http->json(self::URL . '/' . $lang . '/sets');
            $this->totalSets += count($result);

            foreach ($result as $set) {
                $this->totalCards += $set['cardCount']['total'];
            }
        }
    }

    /**
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws ExceptionInterface
     */
    public function importSets(IconImportType $importType, ?callable $onProgress = null): void
    {
        $progress = new ProgressReporter($this->totalSets);
        foreach ($this->language->getSupportedLanguages() as $lang) {
            $result = $this->http->json(self::URL . '/' . $lang . '/sets');
            $sets = array_column($this->setRepository->findBy(['lang' => $lang]), null, 'code');

            foreach ($result as $item) {
                $data = $this->transformer->transformSet($this->http->json(self::URL . '/' . $lang . '/sets/' . rawurlencode($item['id'])));
                $data['lang'] = $lang;
                $set = $this->serializer->denormalize($data, Set::class, 'json', [
                    AbstractNormalizer::OBJECT_TO_POPULATE => $sets[$data['code']] ?? null,
                ]);
                $this->entityManager->persist($set);

                foreach ($set->imagePaths as $type => $uri) {
                    $path = $this->publicDir . $uri;
                    if ($data[$type . '_uri'] !== null && ($importType !== IconImportType::NewOnly || !is_file($path))) {
                        if ($type === 'icon') {
                            $data['icon_uri'] = str_replace('univ', $lang, $data['icon_uri']);
                        }
                        $image = $this->downloadImage($data[$type . '_uri']);
                        if ($image !== null) {
                            file_put_contents($path, $image);
                        }
                    }
                }

                $progress->advance();
                $progress->report($onProgress);
            }

            $this->entityManager->flush();
            $this->entityManager->clear();
        }
    }

    /**
     * @throws ORMException
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws ExceptionInterface
     */
    public function importCards(ImageImportType $importType, ?callable $onProgress = null): void
    {
        $sets = $this->setRepository->findAll();
        $progress = new ProgressReporter($this->totalCards);

        foreach ($sets as $set) {
            $result = $this->http->json(self::URL . '/' . $set->lang->value . '/sets/' . rawurlencode($set->code));
            $this->importSetCards($result, $set, $importType, $progress, $onProgress);
        }
    }

    public function finalize(): void {}

    /**
     * Retries transient failures (connection errors, non-200 responses) with a linear backoff.
     * Returns null when the image still can't be fetched, so the caller can skip it; a 404 is
     * permanent, so it gives up immediately instead of being retried.
     *
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws ClientExceptionInterface
     */
    private function downloadImage(string $url, int $maxAttempts = 3): ?string
    {
        $attempt = 0;
        while (true) {
            try {
                return $this->http->image($url);
            } catch (TransportExceptionInterface|HttpResponseException $e) {
                $isNotFound = $e instanceof HttpResponseException && str_starts_with($e->getMessage(), 'Resource not found');
                if ($isNotFound || ++$attempt >= $maxAttempts) {
                    return null;
                }
                usleep($attempt * 500_000);
            }
        }
    }

    /**
     * @throws ORMException
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws ExceptionInterface
     */
    private function importSetCards(array $setData, Set $set, ImageImportType $importType, ProgressReporter $progress, ?callable $onProgress): void
    {
        $items = $this->cardRepository->findBy(['set' => $set]);
        $cards = array_combine(array_map(static fn(Card $item) => $item->details->uniqueId, $items), $items);
        $setRef = $this->entityManager->getReference(Set::class, $set->id);
        $cardImageUris = [];

        $briefs = $setData['cards'];
        foreach ($briefs as $brief) {
            $result = $this->http->json(self::URL . '/' . $set->lang->value . '/cards/' . $brief['id']);
            $result['lang'] = $set->lang->value;
            $data = $this->transformer->transformCard($result);
            $card = $this->serializer->denormalize($data, Card::class, 'json', [
                AbstractNormalizer::OBJECT_TO_POPULATE => $cards[$data['details']['unique_id']] ?? null,
                AbstractNormalizer::DEFAULT_CONSTRUCTOR_ARGUMENTS => [Card::class => [
                    'set' => $setRef,
                ]]
            ]);
            $this->entityManager->persist($card);
            $cardImageUris[$card->id->toRfc4122()] = $data['image_uri'];
            $progress->advance();
            $progress->report($onProgress);
        }

        $this->entityManager->flush();
        $this->entityManager->clear();

        // Queue image jobs for downloading images
        if ($importType !== ImageImportType::SkipAll) {
            $this->imageJobQueue->enqueueBatch(self::GAME->value, $cardImageUris, $importType === ImageImportType::NewOnly);
        }

        // Force garbage collection to prevent memory flooding
        gc_collect_cycles();
    }
}
