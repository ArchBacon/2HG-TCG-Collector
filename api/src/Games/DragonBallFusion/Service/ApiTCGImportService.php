<?php declare(strict_types=1);

namespace App\Games\DragonBallFusion\Service;

use App\Contract\ImportServiceInterface;
use App\Enum\Game;
use App\Enum\IconImportType;
use App\Enum\ImageImportType;
use App\Games\DragonBallFusion\Entity\Card;
use App\Games\DragonBallFusion\Entity\Set;
use App\Games\DragonBallFusion\Repository\CardRepository;
use App\Games\DragonBallFusion\Repository\SetRepository;
use App\Repository\ImageJobQueueRepository;
use App\Service\HttpService;
use App\Service\ProgressReporter;
use App\Service\ZipService;
use Doctrine\ORM\EntityManager;
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\Exception\ORMException;
use JsonException;
use Symfony\Component\DependencyInjection\Attribute\AutoconfigureTag;
use Symfony\Component\Filesystem\Filesystem;
use Symfony\Component\Finder\Finder;
use Symfony\Component\Serializer\Exception\ExceptionInterface;
use Symfony\Component\Serializer\Normalizer\AbstractNormalizer;
use Symfony\Component\Serializer\Normalizer\DenormalizerInterface;
use Symfony\Component\Serializer\SerializerInterface;
use Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface;

/** ApiTCG GitHub API client and Dragon Ball Fusion data import pipeline. */
#[AutoconfigureTag('api.game_service', ['game' => Game::DragonBallFusion->value])]
class ApiTCGImportService implements ImportServiceInterface
{
    private const Game GAME = Game::DragonBallFusion;
    private const string URL = 'https://github.com/apitcg/dragon-ball-fusion-tcg-data';

    private string $dataPath;
    private int $totalCards = 0;

    public function __construct(
        private readonly HttpService $http,
        private readonly SetRepository $setRepository,
        private readonly CardRepository $cardRepository,
        private readonly SerializerInterface&DenormalizerInterface $serializer,
        private readonly EntityManagerInterface $entityManager,
        private readonly ImageJobQueueRepository $imageJobQueue,
        private readonly ZipService $zip,
        private readonly ApiTCGDataTransformer $transformer,

    ) {}

    /**
     * @throws TransportExceptionInterface
     */
    public function prepare(): void
    {
        $path = $this->http->zip(self::URL . '/archive/refs/heads/main.zip');
        $this->dataPath = $this->zip->unpack($path);
    }

    /**
     * @throws ExceptionInterface
     * @throws JsonException
     */
    public function importSets(IconImportType $importType, ?callable $onProgress = null): void
    {
        $finder = new Finder();
        $cardsDir = $this->dataPath . '/dragon-ball-fusion-tcg-data-main/cards/en';
        $finder->files()->in($cardsDir)->name('*.json');
        $total = $finder->count();

        $sets = array_column($this->setRepository->findAll(), null, 'code');
        $progress = new ProgressReporter($total);

        foreach ($finder as $file) {
            $data = json_decode($file->getContents(), true, 512, JSON_THROW_ON_ERROR);
            // We only need to check the set, so checking the first card in a file sorted by sets is enough.
            $transformedData = $this->transformer->transformSet($data[0]);
            $set = $this->serializer->denormalize($transformedData, Set::class, 'json', [
                AbstractNormalizer::OBJECT_TO_POPULATE => $sets[$transformedData['code']] ?? null,
            ]);
            $set->cardCount = count($data);
            $this->totalCards += $set->cardCount;
            $this->entityManager->persist($set);

            // There are no set icons, so there will ony be fallback.webp as a placeholder.

            $progress->advance();
            $progress->report($onProgress);
        }

        $this->entityManager->flush();
        $this->entityManager->clear();
    }

    /**
     * @throws ExceptionInterface
     * @throws ORMException
     * @throws JsonException
     */
    public function importCards(ImageImportType $importType, ?callable $onProgress = null): void
    {
        /** @var list<Set> $sets */
        $sets = $this->setRepository->findAll();
        $progress = new ProgressReporter($this->totalCards);

        foreach ($sets as $set) {
            $cards = array_column($this->cardRepository->findBy(['set' => $set]), null, 'number');
            $result = json_decode(file_get_contents($this->dataPath . '/dragon-ball-fusion-tcg-data-main/cards/en/' . $set->code . '.json'), true, 512, JSON_THROW_ON_ERROR);
            $setRef = $this->entityManager->getReference(Set::class, $set->id);

            /** @var array<string, ?string> $cardImageUris */
            $cardImageUris = [];
            foreach ($result as $item) {
                $data = $this->transformer->transformCard($item);
                $card = $this->serializer->denormalize($data, Card::class, 'json', [
                    AbstractNormalizer::OBJECT_TO_POPULATE => $cards[$data['number']] ?? null,
                    AbstractNormalizer::DEFAULT_CONSTRUCTOR_ARGUMENTS => [Card::class => [
                        'set' => $setRef,
                    ]],
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

    public function finalize(): void
    {
        $filesystem = new Filesystem();
        $filesystem->remove($this->dataPath);
    }
}
