<?php declare(strict_types=1);

namespace App\Controller;

use App\Entity\CardList;
use App\Entity\User;
use App\Enum\CardListType;
use App\Enum\Game;
use App\Repository\AppliedChangeRepository;
use App\Repository\CardListEntryRepository;
use App\Repository\CardListRepository;
use App\Service\UserCardService;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\BadRequestHttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Routing\Requirement\Requirement;
use Symfony\Component\Security\Http\Attribute\CurrentUser;
use Symfony\Component\Security\Http\Attribute\IsGranted;
use Symfony\Component\Uid\Uuid;
use function array_slice;
use function is_array;
use function is_int;
use function is_string;
use function mb_strlen;
use function round;
use function trim;

/**
 * The user's own lists (collections and wishlists): list, create, rename, delete them, and change
 * how many copies of a card are in one.
 *
 * List ids come from the app, so a list made offline can be used before it's synced; creating one
 * that already exists just returns it.
 */
#[Route('/api/users/lists')]
#[IsGranted('ROLE_USER')]
final readonly class CardListController
{
    private const int NAME_MAX_LENGTH = 100;
    private const int PREVIEW_COUNT = 3;

    public function __construct(
        private CardListRepository $lists,
        private CardListEntryRepository $entries,
        private AppliedChangeRepository $appliedChanges,
        private UserCardService $cards,
        private EntityManagerInterface $entityManager,
    ) {}

    /**
     * The user's lists of `type` (default collection), oldest first. With `game`, each has its
     * counts and value for that game, and the cards added to it last (`previews`); without, those
     * are left out.
     *
     * `value` adds up the lowest store price of each card in stock, times its copies.
     */
    #[Route('', methods: ['GET'])]
    public function index(#[CurrentUser] User $user, Request $request): JsonResponse
    {
        $type = CardListType::tryFrom($request->query->getString('type', CardListType::Collection->value))
            ?? throw new BadRequestHttpException('Unknown list type.');
        $game = $request->query->has('game') ? Game::tryFrom($request->query->getString('game')) ?? throw new BadRequestHttpException('Unknown game.') : null;

        $lists = $this->lists->findByUser($user, $type);
        if ($game === null) {
            return new JsonResponse(['lists' => array_map($this->normalizeList(...), $lists)]);
        }

        $quantities = $this->entries->sumQuantitiesByListAndCard($user, $type, $game);
        $storeState = $this->cards->findStoreState($game);

        $result = [];
        foreach ($lists as $list) {
            $cards = $quantities[$list->id->toRfc4122()] ?? [];
            $value = 0.0;
            foreach ($cards as $cardId => $quantity) {
                $value += ($storeState[$cardId]['price'] ?? 0) * $quantity;
            }

            // Newest first, one per card (the rows are per finish)
            $recentIds = [];
            foreach ($this->entries->findMergedByType($user, $type, $game, $list) as $row) {
                $recentIds[$row['cardId']->toRfc4122()] = $row['cardId'];
                if (count($recentIds) === self::PREVIEW_COUNT) {
                    break;
                }
            }
            $found = $this->cards->findCards($game, array_values($recentIds));
            $previews = [];
            foreach ($recentIds as $cardId => $_) {
                if (isset($found[$cardId])) {
                    $previews[] = $this->cards->normalizeCard($found[$cardId]);
                }
            }

            $result[] = [
                ...$this->normalizeList($list),
                'cards' => count($cards),
                'copies' => array_sum($cards),
                'value' => round($value, 2),
                'previews' => $previews,
            ];
        }

        return new JsonResponse(['lists' => $result]);
    }

    /**
     * Creates a list: `{"id": "<uuid>", "type": "collection", "name": "Binder"}`. 201, or 200 with
     * the list as it is when the id already exists.
     */
    #[Route('', methods: ['POST'])]
    public function create(#[CurrentUser] User $user, Request $request): JsonResponse
    {
        $data = self::body($request);
        $id = is_string($data['id'] ?? null) && Uuid::isValid($data['id']) ? Uuid::fromString($data['id']) : throw new BadRequestHttpException('Missing or invalid "id".');
        $type = is_string($data['type'] ?? null) ? CardListType::tryFrom($data['type']) : CardListType::Collection;
        if ($type === null) {
            throw new BadRequestHttpException('Unknown list type.');
        }

        $existing = $this->lists->find($id);
        if ($existing !== null) {
            if (!$existing->user->id->equals($user->id)) {
                throw new BadRequestHttpException('That id is taken.');
            }

            return new JsonResponse($this->normalizeList($existing));
        }

        $list = new CardList($id, $user, $type, self::name($data));
        $this->entityManager->persist($list);
        $this->entityManager->flush();

        return new JsonResponse($this->normalizeList($list), Response::HTTP_CREATED);
    }

    /**
     * Renames a list: `{"name": "Binder"}`.
     */
    #[Route('/{id}', requirements: ['id' => Requirement::UUID], methods: ['PATCH'])]
    public function rename(#[CurrentUser] User $user, string $id, Request $request): JsonResponse
    {
        $list = $this->findList($user, $id);
        $list->name = self::name(self::body($request));
        $this->entityManager->flush();

        return new JsonResponse($this->normalizeList($list));
    }

    /**
     * Deletes a list and everything in it.
     */
    #[Route('/{id}', requirements: ['id' => Requirement::UUID], methods: ['DELETE'])]
    public function delete(#[CurrentUser] User $user, string $id): Response
    {
        $this->entityManager->remove($this->findList($user, $id));
        $this->entityManager->flush();

        return new Response(null, Response::HTTP_NO_CONTENT);
    }

    /**
     * Adds or removes copies of a card: `{"changeId": "<uuid>", "game": "pokemon", "cardId": "<uuid>",
     * "finish": "normal", "delta": 1}` (negative removes, never below 0). Answers with the copies
     * now in the list. `changeId` makes a retried request count once; it's optional.
     */
    #[Route('/{id}/entries', requirements: ['id' => Requirement::UUID], methods: ['POST'])]
    public function changeEntry(#[CurrentUser] User $user, string $id, Request $request): JsonResponse
    {
        $list = $this->findList($user, $id);
        $data = self::body($request);

        $game = is_string($data['game'] ?? null) ? Game::tryFrom($data['game']) : null;
        $cardId = is_string($data['cardId'] ?? null) && Uuid::isValid($data['cardId']) ? Uuid::fromString($data['cardId']) : null;
        $finish = is_string($data['finish'] ?? null) ? trim($data['finish']) : '';
        $delta = $data['delta'] ?? null;
        if ($game === null || $cardId === null || $finish === '' || mb_strlen($finish) > 20 || !is_int($delta)) {
            throw new BadRequestHttpException('Needs "game", "cardId", "finish" and an integer "delta".');
        }
        if ($this->entityManager->find($game->cardClass(), $cardId) === null) {
            throw new NotFoundHttpException("No card with id {$cardId->toRfc4122()}.");
        }

        $changeId = is_string($data['changeId'] ?? null) && Uuid::isValid($data['changeId']) ? Uuid::fromString($data['changeId']) : null;
        $this->entityManager->wrapInTransaction(function () use ($user, $list, $game, $cardId, $finish, $delta, $changeId): void {
            if ($changeId === null || $this->appliedChanges->claim($changeId, $user)) {
                $this->entries->applyDelta($list, $game->value, $cardId, $finish, $delta);
            }
        });

        return new JsonResponse(['quantity' => $this->entries->quantityIn($list, $game->value, $cardId, $finish)]);
    }

    private function findList(User $user, string $id): CardList
    {
        $list = $this->lists->find(Uuid::fromString($id));
        if ($list === null || !$list->user->id->equals($user->id)) {
            throw new NotFoundHttpException("No list with id $id.");
        }

        return $list;
    }

    /**
     * @return array{id: string, type: string, name: string, createdAt: string}
     */
    private function normalizeList(CardList $list): array
    {
        return [
            'id' => $list->id->toRfc4122(),
            'type' => $list->type->value,
            'name' => $list->name,
            'createdAt' => $list->createdAt->format(DATE_ATOM),
        ];
    }

    /**
     * @return array<mixed>
     */
    private static function body(Request $request): array
    {
        $data = json_decode($request->getContent(), true);

        return is_array($data) ? $data : throw new BadRequestHttpException('Invalid JSON body.');
    }

    /**
     * @param array<mixed> $data
     */
    private static function name(array $data): string
    {
        $name = is_string($data['name'] ?? null) ? trim($data['name']) : '';
        if ($name === '' || mb_strlen($name) > self::NAME_MAX_LENGTH) {
            throw new BadRequestHttpException('A name of 1 to 100 characters, please.');
        }

        return $name;
    }
}
