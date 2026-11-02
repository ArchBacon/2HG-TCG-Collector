<?php declare(strict_types=1);

namespace App\Controller;

use App\ApiResource\Set;
use App\Entity\CardList;
use App\Entity\SyncCode;
use App\Entity\User;
use App\Enum\CardListType;
use App\Enum\Game;
use App\Repository\CardListEntryRepository;
use App\Repository\CardListRepository;
use App\Repository\SyncCodeRepository;
use App\Service\UserCardService;
use DateTimeImmutable;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\RateLimiter\RateLimiterFactoryInterface;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Routing\Requirement\EnumRequirement;
use Symfony\Component\Security\Http\Attribute\CurrentUser;
use Symfony\Component\Security\Http\Attribute\IsGranted;
use Symfony\Component\Uid\Uuid;

/**
 * Anonymous user endpoints. The app calls {@see self::create()} once on first startup and stores
 * the returned token; every later request sends it as `Authorization: Bearer <token>`.
 */
#[Route('/api/users')]
final class UserController
{
    private const string FIRST_COLLECTION = 'My Collection';
    private const string FIRST_WISHLIST = 'My Wishlist';

    public function __construct(
        private readonly EntityManagerInterface $entityManager,
        private readonly CardListEntryRepository $entries,
        private readonly CardListRepository $lists,
        private readonly UserCardService $cards,
        private readonly SyncCodeRepository $syncCodes,
        private readonly RateLimiterFactoryInterface $syncCodeRedeemLimiter,
    ) {}

    /**
     * Creates a new anonymous user, with a collection and a wishlist to start with (normal lists,
     * so they can be renamed and deleted). The token is only ever returned here; the server keeps
     * just a hash of its secret part, so a device that loses it has to create a new user.
     */
    #[Route('', methods: ['POST'])]
    public function create(): JsonResponse
    {
        $secret = User::generateSecret();
        $user = new User(User::hashSecret($secret));

        $this->entityManager->persist($user);
        $this->entityManager->persist(new CardList(Uuid::v7(), $user, CardListType::Collection, self::FIRST_COLLECTION));
        $this->entityManager->persist(new CardList(Uuid::v7(), $user, CardListType::Wishlist, self::FIRST_WISHLIST));
        $this->entityManager->flush();

        return new JsonResponse([
            'id' => $user->id->toRfc4122(),
            'token' => $user->id->toRfc4122() . '.' . $secret,
        ], Response::HTTP_CREATED);
    }

    /**
     * Returns the authenticated user, e.g. for the app to check its stored token is still valid.
     */
    #[Route('/validate', methods: ['GET'])]
    #[IsGranted('ROLE_USER')]
    public function me(#[CurrentUser] User $user): JsonResponse
    {
        return new JsonResponse([
            'id' => $user->id->toRfc4122(),
            'createdAt' => $user->createdAt->format(DATE_ATOM),
        ]);
    }

    /**
     * Creates a {@see SyncCode} for the user, to continue as this user on another device. Valid for
     * {@see SyncCode::LIFETIME}, and only once.
     */
    #[Route('/sync-codes', methods: ['POST'])]
    #[IsGranted('ROLE_USER')]
    public function createSyncCode(#[CurrentUser] User $user): JsonResponse
    {
        $syncCode = new SyncCode($user);

        $this->entityManager->persist($syncCode);
        $this->entityManager->flush();

        return new JsonResponse([
            'code' => $syncCode->code,
            'expiresAt' => $syncCode->expiresAt->format(DATE_ATOM),
        ], Response::HTTP_CREATED);
    }

    /**
     * Redeems a {@see SyncCode} (body: `{"code": "..."}`, any case): this device continues as the
     * code's user. Its own user is deleted, with all of its lists. Returns the new token, as
     * {@see self::create()} does; the device must use it from now on.
     *
     * Rate-limited per IP address (`sync_code_redeem` in framework.yaml), as codes are short enough
     * to guess otherwise. Errors: 404 for an unknown, used or expired code, 422 for a code of this
     * user itself, 429 when over the limit (with `Retry-After`).
     */
    #[Route('/sync-codes/redeem', methods: ['POST'])]
    #[IsGranted('ROLE_USER')]
    public function redeemSyncCode(#[CurrentUser] User $user, Request $request): JsonResponse
    {
        $limit = $this->syncCodeRedeemLimiter->create($request->getClientIp() ?? 'unknown')->consume();
        if (!$limit->isAccepted()) {
            return new JsonResponse(
                ['error' => 'too_many_attempts'],
                Response::HTTP_TOO_MANY_REQUESTS,
                ['Retry-After' => (string) max(1, $limit->getRetryAfter()->getTimestamp() - time())],
            );
        }

        $code = $request->toArray()['code'] ?? '';
        $syncCode = is_string($code) ? $this->syncCodes->findRedeemable($code) : null;
        if ($syncCode === null) {
            return new JsonResponse(['error' => 'invalid_code'], Response::HTTP_NOT_FOUND);
        }
        if ($syncCode->user === $user) {
            return new JsonResponse(['error' => 'own_code'], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $syncCode->markUsed();
        $secret = User::generateSecret();
        $syncCode->user->addSyncedSecret($secret);
        $this->entityManager->remove($user); // Its lists go with it (ON DELETE CASCADE)
        $this->entityManager->flush();

        return new JsonResponse([
            'id' => $syncCode->user->id->toRfc4122(),
            'token' => $syncCode->user->id->toRfc4122() . '.' . $secret,
        ]);
    }

    /**
     * Per-TCG and overall totals across all of the user's lists, plus the most recently released
     * set of each TCG. Card counts are copies (summed quantities), not distinct cards.
     *
     * `value` is always 0 until we have price data.
     */
    #[Route('/collection', methods: ['GET'])]
    #[IsGranted('ROLE_USER')]
    public function collectionSummary(#[CurrentUser] User $user): JsonResponse
    {
        $quantities = $this->entries->sumQuantitiesByTypeAndGame($user);

        $tcgs = [];
        foreach (Game::cases() as $game) {
            $tcgs[] = $this->summarizeGame($game, $quantities);
        }

        return new JsonResponse([
            'tcgs' => $tcgs,
            'total' => [
                'value' => 0,
                'collected' => array_sum(array_column($tcgs, 'collected')),
                'wishlisted' => array_sum(array_column($tcgs, 'wishlisted')),
            ],
        ]);
    }

    /**
     * The cards on any of the user's wishlists, merged into one: the same card + finish on several
     * wishlists is one entry with the quantities added up. Grouped per TCG, newest entries first.
     *
     * `price` is the lowest store price (0 when it isn't in stock), and `value` adds those up.
     */
    #[Route('/wishlist', methods: ['GET'])]
    #[IsGranted('ROLE_USER')]
    public function wishlist(#[CurrentUser] User $user): JsonResponse
    {
        $rows = $this->entries->findMergedByType($user, CardListType::Wishlist);

        $tcgs = [];
        foreach (Game::cases() as $game) {
            $gameRows = array_values(array_filter($rows, static fn (array $row): bool => $row['game'] === $game->value));
            if ($gameRows === []) {
                continue;
            }

            $cards = $this->cards->findCards($game, array_column($gameRows, 'cardId'));
            $storeState = $this->cards->findStoreState($game);
            $entries = [];
            foreach ($gameRows as $row) {
                $card = $cards[$row['cardId']->toRfc4122()] ?? null;
                if ($card === null) {
                    continue; // The card was removed from the catalog since it was wishlisted
                }
                $entries[] = $this->cards->normalizeEntry($card, $storeState, [
                    'finish' => $row['finish'],
                    'quantity' => $row['quantity'],
                    'addedAt' => $row['addedAt']->format(DATE_ATOM),
                ]);
            }

            $tcgs[] = [
                'tcg' => $game->value,
                'value' => round(array_sum(array_map(static fn (array $e): float => $e['price'] * $e['quantity'], $entries)), 2),
                'cards' => count($entries),
                'entries' => $entries,
            ];
        }

        return new JsonResponse([
            'total' => ['value' => round(array_sum(array_column($tcgs, 'value')), 2), 'cards' => array_sum(array_column($tcgs, 'cards'))],
            'tcgs' => $tcgs,
        ]);
    }

    /**
     * The {@see self::collectionSummary()} entry for one TCG, plus all of its sets grouped by
     * block. Each set has how many distinct cards of it the user has collected, to compare
     * against its card count.
     *
     * Blocks are ordered by their newest set, and sets within a block newest first. Sets without
     * a block (and games that don't have blocks at all) are grouped under `"block": null`.
     *
     * With `?list=<id>`, only that collection counts.
     */
    #[Route('/collection/{game}', requirements: ['game' => new EnumRequirement(Game::class)], methods: ['GET'])]
    #[IsGranted('ROLE_USER')]
    public function gameCollection(#[CurrentUser] User $user, Game $game, Request $request): JsonResponse
    {
        $list = $this->findListParam($user, $request);
        $collectedBySet = $this->entries->countCollectedCardsBySet($user, $game, $list);

        /** @var list<Set> $sets */
        $sets = $this->entityManager->createQueryBuilder()
            ->select('s')
            ->from($game->setClass(), 's')
            ->orderBy('s.releasedAt', 'DESC')
            ->addOrderBy('s.code', 'DESC')
            ->getQuery()
            ->getResult();

        $blocks = [];
        foreach ($sets as $set) {
            $key = $set->block ?? '';
            $blocks[$key] ??= ['block' => $set->block, 'sets' => []];
            $blocks[$key]['sets'][] = [
                ...$this->cards->normalizeSet($set),
                'collected' => $collectedBySet[$set->id->toRfc4122()] ?? 0,
            ];
        }

        return new JsonResponse([
            ...$this->summarizeGame($game, $this->entries->sumQuantitiesByTypeAndGame($user, $list)),
            'blocks' => array_values($blocks),
        ]);
    }

    /**
     * The cards most recently added to any of the user's collections of $game, newest first, at
     * most `limit` (default 20, max 100). `owned` is the copies across finishes and collections
     * (or in the collection given with `?list=<id>`).
     */
    #[Route('/collection/{game}/recent', requirements: ['game' => new EnumRequirement(Game::class)], methods: ['GET'])]
    #[IsGranted('ROLE_USER')]
    public function recentlyCollected(#[CurrentUser] User $user, Game $game, Request $request): JsonResponse
    {
        $limit = max(1, min(100, $request->query->getInt('limit', 20)));
        $owned = array_slice($this->findOwned($user, $game, $this->findListParam($user, $request)), 0, $limit, true);

        return new JsonResponse(['cards' => $this->normalizeOwned($user, $game, $owned)]);
    }

    /**
     * The user's cards of $game in their collections, or in $list: copies across finishes, keyed by
     * card id (RFC 4122), newest first.
     *
     * @return array<string, array{cardId: Uuid, quantity: int, addedAt: DateTimeImmutable}>
     */
    private function findOwned(User $user, Game $game, ?CardList $list): array
    {
        // One row per finish: merge them per card, keeping the newest first
        $owned = [];
        foreach ($this->entries->findMergedByType($user, CardListType::Collection, $game, $list) as $row) {
            $id = $row['cardId']->toRfc4122();
            $owned[$id] ??= ['cardId' => $row['cardId'], 'quantity' => 0, 'addedAt' => $row['addedAt']];
            $owned[$id]['quantity'] += $row['quantity'];
        }

        return $owned;
    }

    /**
     * @param array<string, array{cardId: Uuid, quantity: int, addedAt: DateTimeImmutable}> $owned from {@see self::findOwned()}
     *
     * @return list<array<string, mixed>>
     */
    private function normalizeOwned(User $user, Game $game, array $owned): array
    {
        $cards = $this->cards->findCards($game, array_column($owned, 'cardId'));
        $storeState = $this->cards->findStoreState($game);
        $quantities = $this->entries->sumQuantitiesByCard($user, $game);

        $entries = [];
        foreach ($owned as $id => $row) {
            if (!isset($cards[$id])) {
                continue; // The card was removed from the catalog since it was collected
            }
            $entries[] = $this->cards->normalizeEntry($cards[$id], $storeState, [
                'owned' => $row['quantity'],
                'wishlisted' => isset($quantities[$id][CardListType::Wishlist->value]),
                'addedAt' => $row['addedAt']->format(DATE_ATOM),
            ]);
        }

        return $entries;
    }

    /**
     * The collection named by `?list=<id>`, or null for all of them.
     */
    private function findListParam(User $user, Request $request): ?CardList
    {
        $id = $request->query->getString('list');
        if ($id === '') {
            return null;
        }

        $list = Uuid::isValid($id) ? $this->lists->find(Uuid::fromString($id)) : null;
        if ($list === null || !$list->user->id->equals($user->id) || $list->type !== CardListType::Collection) {
            throw new NotFoundHttpException("No collection with id $id.");
        }

        return $list;
    }

    /**
     * @param array<string, array<string, int>> $quantities from {@see CardListEntryRepository::sumQuantitiesByTypeAndGame()}
     *
     * @return array<string, mixed>
     */
    private function summarizeGame(Game $game, array $quantities): array
    {
        return [
            'tcg' => $game->value,
            'value' => 0,
            'collected' => $quantities[CardListType::Collection->value][$game->value] ?? 0,
            'wishlisted' => $quantities[CardListType::Wishlist->value][$game->value] ?? 0,
            'latestSet' => ($latest = $this->findLatestReleasedSet($game)) ? $this->cards->normalizeSet($latest) : null,
        ];
    }

    /**
     * The set with the latest release date that isn't in the future (announced sets are often
     * imported ahead of release).
     */
    private function findLatestReleasedSet(Game $game): ?Set
    {
        /** @var ?Set */
        return $this->entityManager->createQueryBuilder()
            ->select('s')
            ->from($game->setClass(), 's')
            ->where('s.releasedAt <= :today')
            ->setParameter('today', new DateTimeImmutable('today'), 'date_immutable')
            ->orderBy('s.releasedAt', 'DESC')
            ->setMaxResults(1)
            ->getQuery()
            ->getOneOrNullResult();
    }
}
