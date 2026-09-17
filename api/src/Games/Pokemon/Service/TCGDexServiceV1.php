<?php declare(strict_types=1);

namespace App\Games\Pokemon\Service;

use App\Contract\ImportServiceInterfaceV1;
use App\Enum\Game;
use App\Enum\IconImportType;
use App\Enum\ImageImportType;
use App\Exception\HttpResponseException;
use App\Games\Pokemon\Entity\Card;
use App\Games\Pokemon\Entity\Set;
use App\Games\Pokemon\Enum\Language;
use App\Games\Pokemon\Repository\CardRepository;
use App\Games\Pokemon\Repository\SetRepository;
use App\Repository\ImageJobQueueRepository;
use App\Service\HttpService;
use App\Service\ImageService;
use App\Service\LanguageService;
use App\Service\ProgressReporter;
use Doctrine\ORM\EntityManagerInterface;
use RuntimeException;
use Symfony\Component\DependencyInjection\Attribute\AutoconfigureTag;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\Serializer\Exception\ExceptionInterface as SerializerExceptionInterface;
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
 * TCGDex API client and Pokémon data import pipeline, in one place.
 */
#[AutoconfigureTag('api.game_service', ['game' => Game::Pokemon->value])]
class TCGDexServiceV1 implements ImportServiceInterfaceV1
{
    private const Game GAME = Game::Pokemon;
    private const string URL = 'https://api.tcgdex.net/v2';
    private const int CARD_BATCH_SIZE = 300;

    public function __construct(
        #[Autowire('%public_dir%')]
        private readonly string $publicDir,
        private readonly HttpService $http,
        private readonly SetRepository $setRepository,
        private readonly CardRepository $cardRepository,
        private readonly SerializerInterface&DenormalizerInterface $serializer,
        private readonly EntityManagerInterface $entityManager,
        private readonly ImageJobQueueRepository $imageJobQueue,
        private readonly ImageService $imageService,
        private readonly LanguageService $languageService,
    ) {}

    /**
     * @throws HttpResponseException
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     */
    public function syncCardInfo(ImageImportType $importType, ?callable $onProgress = null): int
    {
        $listByLang = [];
        foreach ($this->languageService->getSupportedLanguages() as $lang) {
            $listByLang[$lang] = $this->http->json(self::URL . '/' . $lang . '/sets');
        }

        // Keyed "tcgdexId|lang": TCGdex reuses the same set id across languages for some eras
        // (see Set::$tcgdexId), so tcgdexId alone isn't a unique key.
        /** @var array<string, Set> $sets */
        $sets = [];
        $total = 0;
        foreach ($this->setRepository->findAll() as $set) {
            $sets[$set->tcgdexId . '|' . $set->lang->value] = $set;
            $total += $set->cardCount->total;
        }

        $progress = new ProgressReporter($total);
        $newlyImported = 0;
        foreach ($listByLang as $langCode => $list) {
            $lang = Language::from($langCode);
            foreach ($list as $item) {
                $set = $sets[$item['id'] . '|' . $langCode]
                    ?? throw new RuntimeException(sprintf('Set "%s" (%s) was not synced yet — run syncSetInfo first.', $item['id'], $langCode));

                // Already has every card TCGdex lists for it — skip the set-info fetch and the
                // DB diff entirely rather than re-paying both on every resync for a set that
                // can no longer turn up anything new.
                if ($set->cardsFullyImported) {
                    $progress->advance($set->cardCount->total);
                    $progress->report($onProgress);

                    // Skipping the fetch/diff above also means importSetCards() (the only place
                    // that enqueues image jobs) never runs for this set. That's fine for the
                    // default NewOnly behavior — every card here already has a job — but
                    // --all-images explicitly wants existing jobs reset to pending regardless of
                    // whether card data changed, so that still has to happen here.
                    if ($importType === ImageImportType::All) {
                        $cardImageUris = array_map(
                            static fn(?string $uri): ?string => $uri ? $uri . '/high.webp' : null,
                            $this->cardRepository->findImageUrisBySetAndLang($set, $lang),
                        );
                        $this->imageJobQueue->enqueueBatch(self::GAME->value, $cardImageUris, false);
                    }

                    continue;
                }

                $newlyImported += $this->importSetCards($set->tcgdexId, $set->id, $lang, $importType, $progress, $onProgress);
            }
        }

        return $newlyImported;
    }

    /**
     * Imports every not-yet-imported card of one set, in one language. Card ids come from the
     * brief `cards` list already returned by fetching the set itself — TCGdex only gives full
     * card details (attacks, hp, rarity, ...) one card at a time, so each new id still needs its
     * own request, fetched one at a time via {@see self::fetchCards()}. Cards already in the
     * database are skipped entirely — not just the write, the fetch too — so re-running an
     * interrupted sync doesn't re-pay the network cost for cards it already has.
     *
     * @param (callable(int $consideredSoFar, float $fractionComplete): void)|null $onProgress
     * @return int Cards newly imported this set — the actual "cards imported" count the
     *         interface promises. $progress is advanced (and $onProgress reported) for every
     *         card considered, including already-present ones, so the caller doesn't need to
     *         track that separately to keep progress accurate against its total.
     * @throws HttpResponseException
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     */
    private function importSetCards(
        string $tcgdexId,
        Uuid $setId,
        Language $lang,
        ImageImportType $importType,
        ProgressReporter $progress,
        ?callable $onProgress,
    ): int {
        // Raw concatenation would send ids like "SM1+" unencoded — TCGdex 404s on a literal
        // "+" in the path, only accepting it percent-encoded ("%2B").
        $briefList = $this->http->json(self::URL . '/' . $lang->value . '/sets/' . rawurlencode($tcgdexId))['cards'] ?? [];
        $allCardIds = array_column($briefList, 'id');
        if ($allCardIds === []) {
            // TCGdex reports a non-zero cardCount for a handful of sets (mostly promo/jumbo
            // sets) while listing no cards at all for them — nothing to import, and never will
            // be until that changes, so this is "done" the same as any other set. Still caught
            // by syncSetInfo()'s cardCount-based invalidation if TCGdex ever backfills it.
            $this->markSetFullyImported($setId);

            return 0;
        }

        /** @var array<string, Card> $existingCards */
        $existingCards = [];
        foreach ($this->cardRepository->findByTcgdexIds($allCardIds) as $card) {
            if ($card->lang === $lang) {
                $existingCards[$card->tcgdexId] = $card;
            }
        }

        $newCardIds = array_values(array_diff($allCardIds, array_keys($existingCards)));
        unset($existingCards); // not needed past this point — freed now rather than held for the rest of the method

        // Already-present cards are "considered" immediately, in one jump — there's no fetch to
        // report incremental progress against for them.
        $progress->advance(count($allCardIds) - count($newCardIds));
        $progress->report($onProgress);

        if ($newCardIds === []) {
            // Every card TCGdex lists for this set is already in the DB — safe to flag the set
            // done so the next sync skips it outright (see syncCardInfo()).
            $this->markSetFullyImported($setId);

            // Nothing to flush, but findByTcgdexIds() above still hydrated every existing card
            // of this set into the identity map. Without detaching them here, a run that
            // touches many already-imported sets (a resync, or just later sets once earlier
            // ones are caught up) never hits the flush()+clear() below and OOMs from
            // accumulated managed entities alone, well before any new card is persisted.
            $this->entityManager->clear();
            gc_collect_cycles();

            return 0;
        }

        $cardData = $this->fetchCards($lang->value, $newCardIds);

        // A fresh reference rather than reusing a Set passed in from a prior call: the previous
        // set's flush()+clear() below detaches everything, and a plain Uuid survives that.
        $set = $this->entityManager->getReference(Set::class, $setId);
        assert($set instanceof Set);

        /** @var array<string, ?string> $cardImageUris card id (RFC 4122 string) => TCGdex image URL */
        $cardImageUris = [];
        $count = 0;
        foreach ($cardData as $id => $data) {
            // The brief nested "set" on each card can't build a full Set (missing serie,
            // releaseDate, legal, ...) — the real one is injected below instead.
            unset($data['set']);

            // TCGdex's own data occasionally has a dexId like 25.0 instead of 25 — a literal
            // decimal point in the source JSON decodes to a PHP float, which the serializer
            // then rejects for the strictly-typed list<int>. Coerced defensively since this
            // isn't the only card it's happened on and won't be the last.
            if (isset($data['dexId']) && is_array($data['dexId'])) {
                $data['dexId'] = array_map(static fn (mixed $v): int => (int) $v, $data['dexId']);
            }

            $context = [
                AbstractNormalizer::DEFAULT_CONSTRUCTOR_ARGUMENTS => [
                    Card::class => ['set' => $set, 'lang' => $lang],
                ],
            ];

            try {
                $card = $this->serializer->denormalize($data, Card::class, 'json', $context);
            } catch (SerializerExceptionInterface $e) {
                throw new HttpResponseException(sprintf('Could not import card "%s" (%s): %s', $id, $lang->value, $e->getMessage()), 0, $e);
            }
            $this->entityManager->persist($card);
            $cardImageUris[$card->id->toRfc4122()] = $card->imageUri ? $card->imageUri . '/high.webp' : null;
            $count++;
            $progress->advance();
            $progress->report($onProgress);

            // Flushed/cleared every CARD_BATCH_SIZE cards, not just once at the end of the set —
            // mirrors ScryfallService::importCardBatch(). A handful of Pokemon sets run into the
            // hundreds of new cards (e.g. a first-ever full sync, or a big promo/reprint set),
            // and each one carries substantial JSON columns (attacks, abilities, ...); without
            // this, every card in such a set — plus every $existingCards entity hydrated above
            // across all languages — stays resident in the UnitOfWork simultaneously until the
            // whole set finishes, which is an unbounded peak, not the bounded-per-batch memory
            // the final clear() below assumes.
            if ($count % self::CARD_BATCH_SIZE === 0) {
                $this->entityManager->flush();
                $this->entityManager->clear();
                gc_collect_cycles();

                // A fresh reference: clear() just detached the $set proxy used above too.
                $set = $this->entityManager->getReference(Set::class, $setId);
                assert($set instanceof Set);
            }
        }

        $this->entityManager->flush();

        // Every new card fetched above succeeded (a failed fetch/denormalize throws and aborts
        // the whole set before reaching here) — combined with $existingCards, that's every card
        // TCGdex lists for this set, so it's done.
        $this->markSetFullyImported($setId);
        $this->entityManager->clear();

        // Force garbage collection to prevent memory flooding — mirrors
        // ScryfallService::importCardBatch(). clear() detaches entities from Doctrine's
        // identity map, but reference cycles within the detached entity graph (and Doctrine's
        // own UnitOfWork bookkeeping) aren't reclaimed by PHP's incremental refcounting GC
        // alone; across enough sets in one long-running sync, that's a slow OOM.
        gc_collect_cycles();

        if ($importType !== ImageImportType::SkipAll) {
            $this->imageJobQueue->enqueueBatch(self::GAME->value, $cardImageUris, $importType === ImageImportType::NewOnly);
        }

        return $count;
    }

    /**
     * A raw UPDATE rather than loading the Set entity and setting the property through the
     * ORM: this runs once per set on the resync that finally completes it, and shouldn't force
     * a proxy load (and thus a SELECT) right before that same set gets cleared from the
     * identity map anyway.
     */
    private function markSetFullyImported(Uuid $setId): void
    {
        $this->entityManager->getConnection()->executeStatement(
            'UPDATE pokemon_set SET cards_fully_imported = 1 WHERE id = ?',
            [$setId->toBinary()],
        );
    }

    /**
     * One request at a time: firing every card request before reading any back (concurrent,
     * bounded by max_host_connections) triggered what looks like TCGdex throttling concurrent
     * connection bursts — a 24-card set that normally takes ~4s took 114s under concurrent
     * fetching with no code-side cause found. Sequential is slower per set but actually finishes.
     *
     * @param list<string> $cardIds
     * @return array<string, array<string, mixed>>
     * @throws HttpResponseException
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     */
    private function fetchCards(string $lang, array $cardIds): array
    {
        $data = [];
        foreach ($cardIds as $id) {
            // Raw concatenation would send ids like "SM1+" unencoded — TCGdex 404s on a literal
            // "+" in the path, only accepting it percent-encoded ("%2B").
            $data[$id] = $this->http->json(self::URL . '/' . $lang . '/cards/' . rawurlencode($id));
        }

        return $data;
    }

    /**
     * @throws HttpResponseException
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     */
    public function syncSetInfo(?callable $onProgress = null): int
    {
        // Keyed "tcgdexId|lang": TCGdex reuses the same set id across languages for some eras
        // (see Set::$tcgdexId), so tcgdexId alone isn't a unique key.
        /** @var array<string, Set> $sets */
        $sets = [];
        foreach ($this->setRepository->findAll() as $set) {
            $sets[$set->tcgdexId . '|' . $set->lang->value] = $set;
        }

        // Fetched up front (per language) so progress can be reported against a combined total
        // instead of resetting to 0% at the start of each language.
        $listByLang = [];
        $total = 0;
        foreach ($this->languageService->getSupportedLanguages() as $lang) {
            $list = $this->http->json(self::URL . '/' . $lang . '/sets');
            $listByLang[$lang] = $list;
            $total += is_countable($list) ? count($list) : 0;
        }

        $progress = new ProgressReporter($total);
        foreach ($listByLang as $lang => $list) {
            foreach ($list as $item) {
                // Raw concatenation would send ids like "SM1+" unencoded — TCGdex 404s on a
                // literal "+" in the path, only accepting it percent-encoded ("%2B").
                $info = $this->http->json(self::URL . '/' . $lang . '/sets/' . rawurlencode($item['id']));
                $key = $info['id'] . '|' . $lang;

                $context = [
                    AbstractNormalizer::DEFAULT_CONSTRUCTOR_ARGUMENTS => [
                        Set::class => ['lang' => Language::from($lang)],
                    ],
                ];
                if (isset($sets[$key])) {
                    $context[AbstractNormalizer::OBJECT_TO_POPULATE] = $sets[$key];
                }
                // TCGdex does add cards to a set after its initial release (secret rares, later
                // promo waves) — if its reported total grew since last time, a previously
                // "fully imported" set may have new cards to pick up, so the flag can't survive.
                $previousTotal = $sets[$key]->cardCount->total ?? null;
                $set = $this->serializer->denormalize($info, Set::class, 'json', $context);
                if ($previousTotal !== null && $previousTotal !== $set->cardCount->total) {
                    $set->cardsFullyImported = false;
                }
                $this->entityManager->persist($set);
                // Flushed per set, not per language: a few hundred sets total is cheap to keep
                // managed for the whole run, and this way a dropped connection partway through
                // only costs the one set still in flight — not everything fetched so far for
                // the current language.
                $this->entityManager->flush();
                $sets[$key] = $set;
                $progress->advance();
                $progress->report($onProgress);
            }
        }

        $this->entityManager->clear();

        return $progress->report();
    }

    /**
     * @throws HttpResponseException
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws ClientExceptionInterface
     */
    public function syncSetIcons(IconImportType $importType, ?callable $onProgress = null): int
    {
        $sets = $this->setRepository->findAll();
        $progress = new ProgressReporter(count($sets));
        $game = self::GAME->value;

        foreach ($sets as $set) {
            $images = [
                'logo' => $set->logoUri,
                'symbol' => $set->symbolUri,
            ];

            foreach ($images as $type => $uri) {
                // tcgdexId alone isn't unique across languages (see Set::$tcgdexId) — and on
                // case-insensitive filesystems, e.g. en's "xy2" and ja's "XY2" would even
                // collide on the same path, silently overwriting one language's icon.
                $path = "$this->publicDir/$game/sets/{$set->tcgdexId}_{$set->lang->value}_$type";
                if ($importType !== IconImportType::NewOnly || !is_file($path . '.webp')) {
                    if (!$uri) continue;

                    try {
                        $data = $this->http->image($uri . '.png');
                    } catch (\Exception $e) {
                        print $e->getMessage();
                        continue;
                    }
                    $this->imageService->convertAndSave($data, $path);
                }
            }

            $progress->advance();
            $progress->report($onProgress);
        }

        return $progress->report();
    }
}
