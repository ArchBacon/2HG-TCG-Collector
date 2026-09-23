<?php declare(strict_types=1);

namespace App\Games\OnePiece\Service;

use App\Contract\ImportServiceInterface;
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

/** optcgapi API client and One Piece data import pipeline. */
#[AutoconfigureTag('api.game_service', ['game' => Game::OnePiece->value])]
class OPTCGAPIImportService implements ImportServiceInterface
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
        private readonly OPTCGAPIDataTransformer $transformer,
    ) {}

    public function prepare(): void {}

    /**
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws ExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     */
    public function importSets(IconImportType $importType, ?callable $onProgress = null): void
    {
        $result = $this->http->json(self::URL . '/allSets/?format=json');
        $sets = array_column($this->setRepository->findAll(), null, 'code');
        $progress = new ProgressReporter(count($result));

        foreach ($result as $item) {
            $data = $this->transformer->transformSet($item);
            $set = $this->serializer->denormalize($data, Set::class, 'json', [
                AbstractNormalizer::OBJECT_TO_POPULATE => $sets[$data['code']] ?? null,
            ]);
            $this->entityManager->persist($set);

            // There are no set icons, so there will ony be fallback.webp as a placeholder.

            $progress->advance();
            $progress->report($onProgress);
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
        /** @var list<Set> $sets */
        $sets = $this->setRepository->findAll();
        $total = count($this->http->json(self::URL . '/allSetCards/?format=json'));
        $progress = new ProgressReporter($total);

        foreach ($sets as $set) {
            /** @var list<Card> $items */
            $items = $this->cardRepository->findBy(['set' => $set]);
            $cards = array_combine(array_map(static fn(Card $item) => $item->details->uniqueId, $items), $items);
            $result = $this->http->json(self::URL . '/sets/' . $set->code . '/?format=json');
            $setRef = $this->entityManager->getReference(Set::class, $set->id);

            /** @var array<string, ?string> $cardImageUris */
            $cardImageUris = [];
            foreach ($result as $item) {
                $data = $this->transformer->transformCard($item);
                $card = $this->serializer->denormalize($data, Card::class, 'json', [
                    AbstractNormalizer::OBJECT_TO_POPULATE => $cards[$data['details']['unique_id']] ?? null,
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

            if ($importType !== ImageImportType::SkipAll) {
                $this->imageJobQueue->enqueueBatch(self::GAME->value, $cardImageUris, $importType === ImageImportType::NewOnly);
            }

            gc_collect_cycles();
        }
    }

    public function finalize(): void
    {
        /** @var list<Set> $sets */
        $sets = $this->setRepository->findAll();

        foreach ($sets as $set) {
            $total = $this->cardRepository->count(['set' => $set]);
            $set->cardCount = $total;
            $this->entityManager->persist($set);
        }

        $this->entityManager->flush();
    }
}
