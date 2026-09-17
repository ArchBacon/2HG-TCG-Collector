<?php

namespace App\Games\Lorcana\Service;

use App\Contract\ImportServiceInterfaceV1;
use App\Enum\Game;
use App\Enum\IconImportType;
use App\Enum\ImageImportType;
use App\Exception\HttpResponseException;
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

/**
 * lorcana-api API client and Lorcana data import pipeline, in one place.
 */
#[AutoconfigureTag('api.game_service', ['game' => Game::Lorcana->value])]
class LorcanaApiServiceV1 implements ImportServiceInterfaceV1
{
    private const Game GAME = Game::Lorcana;
    private const string URL = 'https://api.lorcana-api.com';

    public function __construct(
        private readonly HttpService $http,
        private readonly SetRepository $setRepository,
        private readonly CardRepository $cardRepository,
        private readonly SerializerInterface&DenormalizerInterface $serializer,
        private readonly EntityManagerInterface $entityManager,
        private readonly ImageJobQueueRepository $imageJobQueue,
    ) {}

    /**
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws ExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     * @throws ORMException
     * @throws HttpResponseException
     */
    public function syncCardInfo(ImageImportType $importType, ?callable $onProgress = null): int
    {
        /** @var list<Set> $sets */
        $sets = $this->setRepository->findAll();
        $total = array_sum(array_column($sets, 'cardCount'));
        $progress = new ProgressReporter($total);

        foreach ($sets as $set) {
            $cards = array_column($this->cardRepository->findBy(['set' => $set]), null, 'uniqueId');
            $result = $this->http->json(self::URL . '/cards/fetch?search=Set_ID=' . $set->setId);
            $setRef = $this->entityManager->getReference(Set::class, $set->id);

            /** @var array<string, ?string> $cardImageUris card id (RFC 4122 string) => image URL */
            $cardImageUris = [];
            foreach ($result as $item) {
                $card = $this->serializer->denormalize($item, Card::class, 'json', [
                    AbstractNormalizer::OBJECT_TO_POPULATE => $cards[$item['Unique_ID']] ?? null,
                    AbstractNormalizer::DEFAULT_CONSTRUCTOR_ARGUMENTS => [Card::class => ['set' => $setRef]],
                ]);
                $this->entityManager->persist($card);
                $cardImageUris[$card->id->toRfc4122()] = $card->imageUri;
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

        return $progress->count();
    }

    /**
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws ExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     * @throws HttpResponseException
     */
    public function syncSetInfo(?callable $onProgress = null): int
    {
        $result = $this->http->json(self::URL . '/sets/all');
        $sets = array_column($this->setRepository->findAll(), null, 'setId');
        $progress = new ProgressReporter(count($result));

        foreach ($result as $item) {
            $set = $this->serializer->denormalize($item, Set::class, 'json', [
                AbstractNormalizer::OBJECT_TO_POPULATE => $sets[$item['Set_ID']] ?? null
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
}
