<?php declare(strict_types=1);

namespace App\Games\Lorcana\Service;

use App\Contract\ImportServiceInterface;
use App\Enum\Game;
use App\Enum\IconImportType;
use App\Enum\ImageImportType;
use App\Games\Lorcana\Entity\Card;
use App\Games\Lorcana\Entity\Set;
use App\Games\Lorcana\Repository\CardRepository;
use App\Games\Lorcana\Repository\SetRepository;
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

/** lorcana-api API client and Lorcana data import pipeline. */
#[AutoconfigureTag('api.game_service', ['game' => Game::Lorcana->value])]
class LorcanaApiImportService implements ImportServiceInterface
{
    private const Game GAME = Game::Lorcana;
    private const string URL = 'https://api.lorcana-api.com';

    private int $totalCards = 0;

    public function __construct(
        private readonly HttpService $http,
        private readonly SetRepository $setRepository,
        private readonly CardRepository $cardRepository,
        private readonly SerializerInterface&DenormalizerInterface $serializer,
        private readonly EntityManagerInterface $entityManager,
        private readonly ImageJobQueueRepository $imageJobQueue,
        private readonly LorcanaApiDataTransformer $transformer,
    ) {}

    public function prepare(): void {}

    /**
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws ExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     */
    public function importSets(IconImportType $importType, ?callable $onProgress = null): void
    {
        $result = $this->http->json(self::URL . '/sets/all');
        $sets = array_column($this->setRepository->findAll(), null, 'code');
        $progress = new ProgressReporter(count($result));

        foreach ($result as $item) {
            $data = $this->transformer->transformSetData($item);
            $set = $this->serializer->denormalize($data, Set::class, 'json', [
                AbstractNormalizer::OBJECT_TO_POPULATE => $sets[$data['code']] ?? null
            ]);
            $this->totalCards += $set->cardCount;
            $this->entityManager->persist($set);

            // Set icons are hard to find and not included in the target API;
            // so set icons are uploaded manually as <set_code>.webp

            $progress->advance();
            $progress->report($onProgress);
        }

        $this->entityManager->flush();
        $this->entityManager->clear();
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
        /** @var Set[] $sets */
        $sets = $this->setRepository->findAll();
        $progress = new ProgressReporter($this->totalCards);

        foreach ($sets as $set) {
            /** @var list<Card> $items */
            $items = $this->cardRepository->findBy(['set' => $set]);
            $cards = array_combine(array_map(static fn(Card $item) => $item->details->uniqueId, $items), $items);
            $result = $this->http->json(self::URL . '/cards/fetch?search=Set_ID=' . $set->code);
            $setRef = $this->entityManager->getReference(Set::class, $set->id);

            /** @var array<string, ?string> $cardImageUris */
            $cardImageUris = [];
            foreach ($result as $item) {
                $data = $this->transformer->transformCardData($item);
                $card = $this->serializer->denormalize($data, Card::class, 'json', [
                    AbstractNormalizer::OBJECT_TO_POPULATE => $cards[$data['details']['unique_id']] ?? null,
                    AbstractNormalizer::DEFAULT_CONSTRUCTOR_ARGUMENTS => [Card::class => ['set' => $setRef]],
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

            // Queue image jobs for downloading images
            if ($importType !== ImageImportType::SkipAll) {
                $this->imageJobQueue->enqueueBatch(self::GAME->value, $cardImageUris, $importType === ImageImportType::NewOnly);
            }
        }
    }

    public function finalize(): void {}
}
