<?php declare(strict_types=1);

namespace App\Games\OnePiece\Service;
use App\Contract\GameServiceInterface;
use App\Enum\Game;
use App\Enum\IconImportType;
use App\Enum\ImageImportType;
use App\Games\OnePiece\Entity\Card;
use App\Games\OnePiece\Entity\Set;
use App\Games\OnePiece\Repository\CardRepository;
use App\Games\OnePiece\Repository\SetRepository;
use App\Repository\ImageJobQueueRepository;
use App\Service\HttpService;
use App\Service\ProgressReporter;
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\Exception\ORMException;
use Symfony\Component\DependencyInjection\Attribute\AutoconfigureTag;
use Symfony\Component\Serializer\Exception\ExceptionInterface;
use Symfony\Component\Serializer\Normalizer\AbstractNormalizer;
use Symfony\Component\Serializer\Normalizer\DenormalizerInterface;
use Symfony\Component\Serializer\SerializerInterface;
use Symfony\Contracts\HttpClient\Exception\ClientExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\DecodingExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\RedirectionExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\ServerExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface;

/**
 * optcgapi API client and One Piece data import pipeline, in one place.
 */
#[AutoconfigureTag('api.game_service', ['game' => Game::OnePiece->value])]
class OPTCGAPIService implements GameServiceInterface
{
    private const Game GAME = Game::OnePiece;
    private const string URL = 'https://www.optcgapi.com/api';

    public function __construct(
        private readonly HttpService $http,
        private readonly SetRepository $setRepository,
        private readonly CardRepository $cardRepository,
        private readonly SerializerInterface&DenormalizerInterface $serializer,
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
     * @throws ExceptionInterface
     */
    public function syncCardInfo(ImageImportType $importType, ?callable $onProgress = null): int
    {
        /** @var list<Set> $sets */
        $sets = $this->setRepository->findAll();
        $total = count($this->http->json(self::URL . '/allSetCards/'));
        $progress = new ProgressReporter($total);

        foreach ($sets as $set) {
            // optcgapi doesn't always suffix a genuinely distinct print (parallel, alt art, ...)
            // with its own card_image_id, so card_image (the asset URL) is needed alongside it
            // to reliably tell such prints apart; see Card::$printId.
            $cards = [];
            foreach ($this->cardRepository->findBy(['set' => $set]) as $existingCard) {
                $cards[$existingCard->printId . '|' . $existingCard->imageUri] = $existingCard;
            }
            $result = $this->http->json(self::URL . '/sets/' . $set->setId . '/?format=json');
            $setRef = $this->entityManager->getReference(Set::class, $set->id);

            $cardIds = [];
            foreach ($result as $item) {
                $lookupKey = ($item['card_image_id'] ?? '') . '|' . ($item['card_image'] ?? '');
                $card = $this->serializer->denormalize($this->sanitizeCardData($item), Card::class, 'json', [
                    AbstractNormalizer::OBJECT_TO_POPULATE => $cards[$lookupKey] ?? null,
                    AbstractNormalizer::DEFAULT_CONSTRUCTOR_ARGUMENTS => [Card::class => ['set' => $setRef]],
                ]);
                $this->entityManager->persist($card);
                $cardIds[] = $card->id;
                $progress->advance();
                $progress->report($onProgress);
            }

            $this->entityManager->flush();
            $this->entityManager->clear();

            if ($importType !== ImageImportType::SkipAll) {
                $this->imageJobQueue->enqueueBatch(self::GAME->value, $cardIds, $importType === ImageImportType::NewOnly);
            }

            gc_collect_cycles();
        }

        return $progress->count();
    }

    /**
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws ExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     */
    public function syncSetInfo(?callable $onProgress = null): int
    {
        $result = $this->http->json(self::URL . '/allSets/?format=json');
        $sets = array_column($this->setRepository->findAll(), null, 'setId');
        $progress = new ProgressReporter(count($result));

        foreach ($result as $item) {
            $set = $this->serializer->denormalize($item, Set::class, 'json', [
                AbstractNormalizer::OBJECT_TO_POPULATE => $sets[$item['set_id']] ?? null,
            ]);
            $this->entityManager->persist($set);
            $progress->advance();
            $progress->report($onProgress);
        }

        $this->entityManager->flush();
        $this->entityManager->clear();

        return $progress->count();
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
        foreach (['card_cost', 'card_power', 'life', 'counter_amount'] as $field) {
            if (array_key_exists($field, $item)) {
                $item[$field] = ($item[$field] === 'NULL' || $item[$field] === null) ? null : (int) $item[$field];
            }
        }

        return $item;
    }
}
