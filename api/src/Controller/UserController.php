<?php declare(strict_types=1);

namespace App\Controller;

use App\ApiResource\Set;
use App\Entity\User;
use App\Enum\CardListType;
use App\Enum\Game;
use App\Repository\CardListEntryRepository;
use DateTimeImmutable;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Routing\Requirement\EnumRequirement;
use Symfony\Component\Security\Http\Attribute\CurrentUser;
use Symfony\Component\Security\Http\Attribute\IsGranted;

/**
 * Anonymous user endpoints. The app calls {@see self::create()} once on first startup and stores
 * the returned token; every later request sends it as `Authorization: Bearer <token>`.
 */
#[Route('/api/users')]
final class UserController
{
    public function __construct(
        private readonly EntityManagerInterface $entityManager,
        private readonly CardListEntryRepository $entries,
    ) {}

    /**
     * Creates a new anonymous user. The token is only ever returned here; the server keeps just a
     * hash of its secret part, so a device that loses it has to create a new user.
     */
    #[Route('', methods: ['POST'])]
    public function create(): JsonResponse
    {
        $secret = User::generateSecret();
        $user = new User(User::hashSecret($secret));

        $this->entityManager->persist($user);
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
     * The {@see self::collectionSummary()} entry for one TCG, plus all of its sets grouped by
     * block. Each set has how many distinct cards of it the user has collected, to compare
     * against its card count.
     *
     * Blocks are ordered by their newest set, and sets within a block newest first. Sets without
     * a block (and games that don't have blocks at all) are grouped under `"block": null`.
     */
    #[Route('/collection/{game}', requirements: ['game' => new EnumRequirement(Game::class)], methods: ['GET'])]
    #[IsGranted('ROLE_USER')]
    public function gameCollection(#[CurrentUser] User $user, Game $game): JsonResponse
    {
        $collectedBySet = $this->entries->countCollectedCardsBySet($user, $game);

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
                ...$this->normalizeSet($set),
                'collected' => $collectedBySet[$set->id->toRfc4122()] ?? 0,
            ];
        }

        return new JsonResponse([
            ...$this->summarizeGame($game, $this->entries->sumQuantitiesByTypeAndGame($user)),
            'blocks' => array_values($blocks),
        ]);
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
            'latestSet' => ($latest = $this->findLatestReleasedSet($game)) ? $this->normalizeSet($latest) : null,
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

    /**
     * @return array<string, mixed>
     */
    private function normalizeSet(Set $set): array
    {
        return [
            'id' => $set->id->toRfc4122(),
            'lang' => $set->lang?->value,
            'code' => $set->code,
            'name' => $set->name,
            'cardCount' => $set->cardCount,
            'releasedAt' => $set->releasedAt?->format('Y-m-d'),
            'images' => $set->images,
        ];
    }
}
