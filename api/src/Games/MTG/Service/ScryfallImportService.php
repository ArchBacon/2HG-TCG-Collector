<?php declare(strict_types=1);

namespace App\Games\MTG\Service;

use App\Contract\ImportServiceInterface;
use App\Enum\Game;
use App\Enum\IconImportType;
use App\Enum\ImageImportType;
use App\Games\MTG\Entity\Card;
use App\Games\MTG\Entity\Set;
use App\Games\MTG\Repository\SetRepository;
use App\Service\HttpService;
use App\Service\LanguageService;
use App\Service\ProgressReporter;
use App\Service\ZipService;
use Doctrine\ORM\EntityManagerInterface;
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
        private readonly SerializerInterface&DenormalizerInterface $serializer,
        private readonly EntityManagerInterface $entityManager,
        private readonly ZipService $zip,
        private readonly LanguageService $language,
    ) {}

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
            $set = $this->serializer->denormalize($item, Set::class, 'json', [
                AbstractNormalizer::OBJECT_TO_POPULATE => $sets[$item['code']] ?? null,
                AbstractNormalizer::GROUPS => ['external_api'],
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

    /** @inheritDoc */
    public function importCards(ImageImportType $importType, ?callable $onProgress = null): void
    {
        $result = $this->http->json(self::URL . '/bulk-data/all-cards');
        $zip = $this->http->download($result['jsonl_download_uri'], "{$result['id']}.jsonl.gz");
        $file = $this->zip->unpack($zip);
        $fileSize = filesize($file);

        $progress = new ProgressReporter($fileSize);
        $sets = array_column($this->setRepository->findAll(), 'id', 'code');

        $resource = fopen($file, 'rb');
        if ($resource === false) {
            throw new RuntimeException(sprintf('Could not open downloaded bulk data file "%s".', $file));
        }

        try {
            $count = 0;
            foreach (Jsonl::decodeFromResource($resource, true) as $item) {
                if (!$this->language->isSupported($item['lang'])) {
                    continue;
                }
                $lastTell = ftell($resource);

                $setId = $sets[$item['set']] ?? throw new RuntimeException(sprintf('Unknown set code "%s" for card "%s".', $item['set'], $item['id']));
                $set = $this->entityManager->getReference(Set::class, $setId);
                assert($set instanceof Set);

                /** @var list<Card> $cardFaces */
                $cardFaces = [];
                $faces = $this->extractFaces($item);
                // TODO: map related and variants from scryfal id to internal id
                foreach ($faces as $key => $face) {
                    $card = $this->serializer->denormalize($face, Card::class, 'json', [
                        AbstractNormalizer::OBJECT_TO_POPULATE => null, // TODO: get existing card
                        AbstractNormalizer::GROUPS => ['external_api'],
                        AbstractNormalizer::IGNORED_ATTRIBUTES => ['id', 'set'],
                        AbstractNormalizer::DEFAULT_CONSTRUCTOR_ARGUMENTS => [
                            Card::class => ['set' => $set, 'faceIndex' => $key],
                        ],
                    ]);
                    $cardFaces[] = $card;
                }

                foreach ($cardFaces as $face) {
                    $face->faces = array_column($cardFaces, 'id');
                    $this->entityManager->persist($face);
                }

                // TODO: create image job

                if ($count % 200 === 0) {
                    $this->entityManager->flush();
                    $this->entityManager->clear();
                    gc_collect_cycles();
                }

                $progress->advance(ftell($resource) - $lastTell);
                $progress->report($onProgress);
                $count++;
            }

            // flush any remaining persisted cards
            $this->entityManager->flush();
            $this->entityManager->clear();
        } finally {
            fclose($resource);
            unlink($file);
        }
    }

    private function extractFaces(array $data): array
    {
        // related
        if (isset($data['all_parts'])) {
            foreach ($data['all_parts'] as $part) {
                if ($part['component'] !== 'combo_piece') {
                    $data['related'][] = $part['id'];
                }
            }
        }

        // variants
        if ($data['variation'] && isset($data['variant_of'])) {
            $data['variants'][] = $data['variant_of'];
        }

        $sharedFaceData = [
            'related' => $data['related'] ?? [],
            'variants' => $data['variants'] ?? [],
            'details' => [
                'scryfall_id' => $data['id'],
                'layout' => $data['layout'],
                'cmc' => $data['cmc'] ?? null,
                'colors' => $data['color_identity'],
                'legalities' => $data['legalities'],
                'finishes' => $data['finishes'],
                'oversized' => $data['oversized'],
                'promo' => $data['promo'],
                'frame' => $data['frame'],
            ],
        ];

        $faceList = $data['card_faces'] ?? [$data];
        // return new face data, but also keep some of the original data
        return array_map(fn ($faceData) => array_merge($this->makeCardFace($sharedFaceData, $faceData), $faceList), $data);
    }

    // TODO: make sure image uri comes from top-level in case of split cards and such
    private function makeCardFace(array $face, array $data): array
    {
        $newFace = $face;
        $newFace['mana_cost'] = $data['mana_cost'] ?? null;
        $newFace['power'] = $data['power'] ?? null;
        $newFace['toughness'] = $data['toughness'] ?? null;
        $newFace['loyalty'] = $data['loyalty'] ?? null;
        $newFace['artist'] = $data['artist'] ?? null;
        $newFace['image_uri'] = $data['image_uris']['png'];

        return $newFace;
    }
}
