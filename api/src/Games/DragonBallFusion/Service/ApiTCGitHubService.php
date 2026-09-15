<?php declare(strict_types=1);

namespace App\Games\DragonBallFusion\Service;

use App\Contract\GameServiceInterface;
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
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\Exception\ORMException;
use Symfony\Component\DependencyInjection\Attribute\AutoconfigureTag;
use Symfony\Component\Filesystem\Filesystem;
use Symfony\Component\Finder\Finder;
use Symfony\Component\Serializer\Exception\ExceptionInterface;
use Symfony\Component\Serializer\Normalizer\AbstractNormalizer;
use Symfony\Component\Serializer\Normalizer\DenormalizerInterface;
use Symfony\Component\Serializer\SerializerInterface;
use Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface;
use ZipArchive;

/**
 * ApiTCG GitHub API client and Dragon Ball Fusion data import pipeline, in one place.
 */
#[AutoconfigureTag('api.game_service', ['game' => Game::DragonBallFusion->value])]
class ApiTCGitHubService implements GameServiceInterface
{
    private const Game GAME = Game::DragonBallFusion;
    private const string URL = 'https://github.com/apitcg/dragon-ball-fusion-tcg-data';

    private readonly string $dataPath;
    private int $totalCards = 0;

    /**
     * @throws TransportExceptionInterface
     */
    public function __construct(
        private readonly HttpService $http,
        private readonly SetRepository $setRepository,
        private readonly CardRepository $cardRepository,
        private readonly SerializerInterface&DenormalizerInterface $serializer,
        private readonly EntityManagerInterface $entityManager,
        private readonly ImageJobQueueRepository $imageJobQueue,
    ) {
        $path = $this->http->zip(self::URL . '/archive/refs/heads/main.zip');
        $zip = new ZipArchive();

        if (!$zip->open($path)) {
            throw new \RuntimeException(sprintf('Could not open zip file "%s"', $path));
        }
        $extractPath = str_replace('.zip', '', $path);
        if (!mkdir($extractPath, 0755, true) && !is_dir($extractPath)) {
            throw new \RuntimeException(sprintf('Directory "%s" was not created', $extractPath));
        }

        $zip->extractTo($extractPath);
        $zip->close();
        unlink($path);
        $this->dataPath = $extractPath;
    }

    public function __destruct()
    {
        $filesystem = new Filesystem();
        $filesystem->remove($this->dataPath);
    }

    /**
     * @throws ExceptionInterface
     * @throws \JsonException
     * @throws ORMException
     */
    public function syncCardInfo(ImageImportType $importType, ?callable $onProgress = null): int
    {
        /** @var Set[] $sets */
        $sets = $this->setRepository->findAll();
        $progress = new ProgressReporter($this->totalCards);

        foreach ($sets as $set) {
            $cards = array_column($this->cardRepository->findBy(['set' => $set]), null, 'cardId');
            $result = json_decode(file_get_contents($this->dataPath . '/dragon-ball-fusion-tcg-data-main/cards/en/' . $set->setId . '.json'), true, 512, JSON_THROW_ON_ERROR);
            $setRef = $this->entityManager->getReference(Set::class, $set->id);

            $cardIds = [];
            foreach ($result as $item) {
                unset($item['set']);
                $card = $this->serializer->denormalize($this->sanitizeCardData($item), Card::class, 'json', [
                    AbstractNormalizer::OBJECT_TO_POPULATE => $cards[$item['id']] ?? null,
                    AbstractNormalizer::DEFAULT_CONSTRUCTOR_ARGUMENTS => [Card::class => [
                        'set' => $setRef,
                    ]],
                ]);
                $this->entityManager->persist($card);
                $cardIds[] = $card->id;
                $progress->advance();
                $progress->report($onProgress);
            }

            $this->entityManager->flush();
            $this->entityManager->clear();

            // Queue image jobs for downloading images
            if ($importType !== ImageImportType::SkipAll) {
                $this->imageJobQueue->enqueueBatch(self::GAME->value, $cardIds, $importType === ImageImportType::NewOnly);
            }

            // Force garbage collection to prevent memory flooding
            gc_collect_cycles();
        }

        return $progress->report();
    }

    /**
     * @throws ExceptionInterface
     * @throws \JsonException
     */
    public function syncSetInfo(?callable $onProgress = null): int
    {
        $finder = new Finder();
        $cardsDir = $this->dataPath . '/dragon-ball-fusion-tcg-data-main/cards/en';
        $finder->files()->in($cardsDir)->name('*.json');
        $total = $finder->count();

        $sets = array_column($this->setRepository->findAll(), null, 'setId');
        $progress = new ProgressReporter($total);

        foreach ($finder as $file) {
            $data = json_decode($file->getContents(), true, 512, JSON_THROW_ON_ERROR);
            // We only need to check the set, so checking the first card in a file sorted by sets is enough.
            $setData = $data[0]['set'];
            $set = $this->serializer->denormalize($setData, Set::class, 'json', [
                AbstractNormalizer::OBJECT_TO_POPULATE => $sets[$setData['id']] ?? null,
            ]);
            $this->entityManager->persist($set);
            $progress->advance();
            $progress->report($onProgress);

            // Add total cards in set for card importer
            $this->totalCards += count($data);
        }

        $this->entityManager->flush();
        $this->entityManager->clear();


        return $progress->report();
    }

    public function syncSetIcons(IconImportType $importType, ?callable $onProgress = null): int
    {
        // Set icons are hard to find and not included in the target API; so set icons are uploaded manually and
        // named <setId>.webp

        return 0;
    }

    /**
     * @param array<string, mixed> $item
     * @return array<string, mixed>
     */
    private function sanitizeCardData(array $item): array
    {
        foreach (['cost', 'power', 'comboPower'] as $field) {
            if (array_key_exists($field, $item)) {
                $item[$field] = $item[$field] === '-' ? null : (int) $item[$field];
            }
        }

        if (($item['rarity'] ?? null) === '') {
            $item['rarity'] = null;
        }

        $item['imageUri'] = $item['images']['large'] ?? $item['images']['small'] ?? null;

        return $item;
    }
}
