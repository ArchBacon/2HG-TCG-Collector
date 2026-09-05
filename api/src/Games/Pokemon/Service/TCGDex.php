<?php declare(strict_types=1);

namespace App\Games\Pokemon\Service;

use App\Contract\GameServiceInterface;
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
use App\Service\ImageService;
use Doctrine\ORM\EntityManagerInterface;
use RuntimeException;
use Symfony\Component\DependencyInjection\Attribute\AutoconfigureTag;
use Symfony\Component\Serializer\Exception\ExceptionInterface as SerializerExceptionInterface;
use Symfony\Component\Serializer\Normalizer\AbstractNormalizer;
use Symfony\Component\Serializer\Normalizer\DenormalizerInterface;
use Symfony\Component\Serializer\SerializerInterface;
use Symfony\Component\Uid\Uuid;
use Symfony\Contracts\HttpClient\Exception\DecodingExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface;
use Symfony\Contracts\HttpClient\HttpClientInterface;
use Symfony\Contracts\HttpClient\ResponseInterface;
use function sprintf;

/**
 * TCGDex API client and Pokémon data import pipeline, in one place.
 */
#[AutoconfigureTag('api.game_service', ['game' => Game::Pokemon->value])]
class TCGDex implements GameServiceInterface
{
    private const Game GAME = Game::Pokemon;
    private const string URL = 'https://api.tcgdex.net/v2';
    private readonly array $supportedLanguages;

    /** @param list<string> $supportedLanguages */
    public function __construct(
        private readonly string $publicDir,
        private readonly HttpClientInterface $http,
        private readonly SetRepository $setRepository,
        private readonly CardRepository $cardRepository,
        private readonly SerializerInterface&DenormalizerInterface $serializer,
        private readonly EntityManagerInterface $entityManager,
        private readonly ImageJobQueueRepository $imageJobQueue,
        private readonly ImageService $imageService,
        array $supportedLanguages,
    ) {
        $this->supportedLanguages = array_values(array_filter(
            $supportedLanguages,
            static fn (?string $lang): bool => $lang !== null && $lang !== '',
        ));
    }

    /**
     * @throws HttpResponseException
     */
    public function syncCardInfo(ImageImportType $importType, ?callable $onProgress = null): int
    {
        // Fetch each language's set list up front: which sets exist per locale (TCGdex has no
        // "list every card" endpoint), and lets progress be reported against a combined total
        // across all languages instead of restarting at 0% for each one.
        $listByLang = [];
        foreach ($this->supportedLanguages as $lang) {
            $response = $this->http->request('GET', self::URL . '/' . $lang . '/sets');
            $listByLang[$lang] = $this->readJson($response, sprintf('set list (%s)', $lang));
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

        $considered = 0;
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
                    $considered += $set->cardCount->total;
                    if ($onProgress !== null) {
                        $onProgress($considered, $total > 0 ? $considered / $total : 1.0);
                    }

                    continue;
                }

                [$setConsidered, $setImported] = $this->importSetCards($set->tcgdexId, $set->id, $lang, $importType, $onProgress, $considered, $total);
                $considered += $setConsidered;
                $newlyImported += $setImported;
            }
        }

        return $newlyImported;
    }

    /**
     * Imports every not-yet-imported card of one set, in one language. Card ids come from the
     * brief `cards` list already returned by {@see self::fetchSetInfo()} — TCGdex only gives
     * full card details (attacks, hp, rarity, ...) one card at a time, so each new id still
     * needs its own request, fetched one at a time via {@see self::fetchCards()}. Cards already
     * in the database are skipped entirely — not just the write, the fetch too — so re-running
     * an interrupted sync doesn't re-pay the network cost for cards it already has.
     *
     * @param (callable(int $consideredSoFar, float $fractionComplete): void)|null $onProgress
     * @return array{0: int, 1: int} [cards considered this set (imported + already present),
     *         cards newly imported this set] — the caller needs both: the first to keep
     *         progress accurate against $total even when most cards get skipped, the second is
     *         the actual "cards imported" count the interface promises.
     * @throws HttpResponseException
     */
    private function importSetCards(
        string $tcgdexId,
        Uuid $setId,
        Language $lang,
        ImageImportType $importType,
        ?callable $onProgress,
        int $consideredSoFar,
        int $total,
    ): array {
        $briefList = $this->fetchSetInfo($lang->value, $tcgdexId)['cards'] ?? [];
        $allCardIds = array_column($briefList, 'id');
        if ($allCardIds === []) {
            // TCGdex reports a non-zero cardCount for a handful of sets (mostly promo/jumbo
            // sets) while listing no cards at all for them — nothing to import, and never will
            // be until that changes, so this is "done" the same as any other set. Still caught
            // by syncSetInfo()'s cardCount-based invalidation if TCGdex ever backfills it.
            $this->markSetFullyImported($setId);

            return [0, 0];
        }

        /** @var array<string, Card> $existingCards */
        $existingCards = [];
        foreach ($this->cardRepository->findByTcgdexIds($allCardIds) as $card) {
            if ($card->lang === $lang) {
                $existingCards[$card->tcgdexId] = $card;
            }
        }

        $newCardIds = array_values(array_diff($allCardIds, array_keys($existingCards)));

        // Already-present cards are "considered" immediately, in one jump — there's no fetch to
        // report incremental progress against for them.
        $consideredSoFar += count($allCardIds) - count($newCardIds);
        if ($onProgress !== null) {
            $onProgress($consideredSoFar, $total > 0 ? $consideredSoFar / $total : 1.0);
        }

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

            return [count($allCardIds), 0];
        }

        $cardData = $this->fetchCards($lang->value, $newCardIds);

        // A fresh reference rather than reusing a Set passed in from a prior call: the previous
        // set's flush()+clear() below detaches everything, and a plain Uuid survives that.
        $set = $this->entityManager->getReference(Set::class, $setId);
        assert($set instanceof Set);

        $cardEntityIds = [];
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
            $cardEntityIds[] = $card->id;
            $count++;
            $consideredSoFar++;

            if ($onProgress !== null) {
                $onProgress($consideredSoFar, $total > 0 ? $consideredSoFar / $total : 1.0);
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
            $this->imageJobQueue->enqueueBatch(self::GAME->value, $cardEntityIds, $importType === ImageImportType::NewOnly);
        }

        return [count($allCardIds), $count];
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
     */
    private function fetchCards(string $lang, array $cardIds): array
    {
        $data = [];
        foreach ($cardIds as $id) {
            // Raw concatenation would send ids like "SM1+" unencoded — TCGdex 404s on a literal
            // "+" in the path, only accepting it percent-encoded ("%2B").
            $response = $this->http->request('GET', self::URL . '/' . $lang . '/cards/' . rawurlencode($id));
            $data[$id] = $this->readJson($response, sprintf('card "%s" (%s)', $id, $lang));
        }

        return $data;
    }

    /**
     * @throws HttpResponseException
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
        foreach ($this->supportedLanguages as $lang) {
            $response = $this->http->request('GET', self::URL . '/' . $lang . '/sets');
            $list = $this->readJson($response, sprintf('set list (%s)', $lang));
            $listByLang[$lang] = $list;
            $total += is_countable($list) ? count($list) : 0;
        }

        $syncedSetCount = 0;
        foreach ($listByLang as $lang => $list) {
            foreach ($list as $item) {
                $info = $this->fetchSetInfo($lang, $item['id']);
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
                $syncedSetCount++;
                if ($onProgress !== null) {
                    $onProgress($syncedSetCount, $total > 0 ? $syncedSetCount / $total : 1.0);
                }
            }
        }

        $this->entityManager->clear();

        return $syncedSetCount;
    }

    /**
     * @throws HttpResponseException
     */
    public function syncSetIcons(IconImportType $importType, ?callable $onProgress = null): int
    {
        $downloaded = 0;
        $sets = $this->setRepository->findAll();
        $total = count($sets);
        $processed = 0;
        $game = self::GAME->value;

        foreach ($sets as $set) {
            $images = [
                'logo' => $set->logoUri,
                'symbol' => $set->symbolUri,
            ];

            $processed++;
            foreach ($images as $type => $uri) {
                // tcgdexId alone isn't unique across languages (see Set::$tcgdexId) — and on
                // case-insensitive filesystems, e.g. en's "xy2" and ja's "XY2" would even
                // collide on the same path, silently overwriting one language's icon.
                $path = "$this->publicDir/$game/sets/{$set->tcgdexId}_{$set->lang->value}_$type";
                if ($importType !== IconImportType::NewOnly || !is_file($path . '.webp')) {
                    if (!$uri) continue;

                    $response = $this->http->request('GET', $uri . '.png');
                    $data = $this->readContent($response, sprintf('%s icon for set "%s"', $type, $set->tcgdexId));
                    $this->imageService->convertAndSave($data, $path);
                    $downloaded++;
                }
            }

            if ($onProgress !== null) {
                $onProgress($processed, $total > 0 ? $processed / $total : 1.0);
            }
        }

        return $downloaded;
    }

    /**
     * @throws HttpResponseException
     */
    public function fetchSetInfo(string $lang, string $id): array
    {
        // Raw concatenation would send ids like "SM1+" unencoded — TCGdex 404s on a literal
        // "+" in the path, only accepting it percent-encoded ("%2B").
        $response = $this->http->request('GET', self::URL . '/' . $lang . '/sets/' . rawurlencode($id));

        return $this->readJson($response, sprintf('set "%s" (%s)', $id, $lang));
    }

    /**
     * Reads and JSON-decodes a response, wrapping any failure — a dropped connection, a
     * timeout, a bad status code, malformed JSON — with $context (e.g. `card "SVLS-019" (ja)`)
     * so the error says *what* was being fetched. A stack trace alone (even at -v) only shows
     * where in the code the failure happened, never which runtime id/language was in flight.
     *
     * @throws HttpResponseException
     */
    private function readJson(ResponseInterface $response, string $context): array
    {
        try {
            $status = $response->getStatusCode();
            if ($status !== 200) {
                throw new HttpResponseException(sprintf('Could not fetch %s: HTTP %d.', $context, $status));
            }

            return $response->toArray();
        } catch (TransportExceptionInterface|DecodingExceptionInterface $e) {
            throw new HttpResponseException(sprintf('Could not fetch %s: %s', $context, $e->getMessage()), 0, $e);
        }
    }

    /** @see self::readJson() — same, but for raw (non-JSON) content like set icon images. */
    private function readContent(ResponseInterface $response, string $context): string
    {
        try {
            $status = $response->getStatusCode();
            if ($status !== 200) {
                throw new HttpResponseException(sprintf('Could not fetch %s: HTTP %d.', $context, $status));
            }

            return $response->getContent();
        } catch (TransportExceptionInterface $e) {
            throw new HttpResponseException(sprintf('Could not fetch %s: %s', $context, $e->getMessage()), 0, $e);
        }
    }
}
