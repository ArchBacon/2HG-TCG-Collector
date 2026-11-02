<?php declare(strict_types=1);

namespace App\Controller;

use App\ApiResource\Card;
use App\Entity\CardList;
use App\Entity\CardListingCondition;
use App\Entity\User;
use App\Enum\CardListType;
use App\Enum\Game;
use App\Repository\CardListEntryRepository;
use App\Repository\CardListRepository;
use App\Service\UserCardService;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Routing\Requirement\EnumRequirement;
use Symfony\Component\Routing\Requirement\Requirement;
use Symfony\Component\Security\Http\Attribute\CurrentUser;
use Symfony\Component\Security\Http\Attribute\IsGranted;
use Symfony\Component\Uid\Uuid;

/**
 * Cards as the app shows them: the card, its store state, and the user's own state for it (copies
 * owned, wishlisted).
 */
#[Route('/api/users')]
#[IsGranted('ROLE_USER')]
final readonly class UserCardController
{
    private const int PER_PAGE = 30;

    public function __construct(
        private CardListEntryRepository $entries,
        private CardListRepository $lists,
        private UserCardService $cards,
    ) {}

    /**
     * One page of $game's cards ({@see self::PER_PAGE} per page), and how many match in total.
     *
     * Query parameters, all optional:
     * - `page`: from 1
     * - `set`: a set code; `rarity`; `artist`
     * - `owned`, `wishlisted`, `inStore`: `1` for only those cards
     * - `search`: part of the name, any case
     * - `list`: a collection's or wishlist's id, for only the cards in it; for a collection, `owned`
     *   is then the copies in it
     * - `sort`: `number` (set order, newest set first, then number; the default), `priceHigh`,
     *   `priceLow` or `name`
     */
    #[Route('/catalog/{game}', requirements: ['game' => new EnumRequirement(Game::class)], methods: ['GET'])]
    public function catalog(#[CurrentUser] User $user, Game $game, Request $request): JsonResponse
    {
        $query = $request->query;
        $page = max(1, $query->getInt('page', 1));
        $list = $this->findList($user, $request);

        $result = $this->cards->findCatalogPage($game, $user, $list, [
            'set' => $query->getString('set'),
            'rarity' => $query->getString('rarity'),
            'artist' => $query->getString('artist'),
            'search' => trim($query->getString('search')),
            'owned' => $query->getBoolean('owned'),
            'wishlisted' => $query->getBoolean('wishlisted'),
            'inStore' => $query->getBoolean('inStore'),
        ], $query->getString('sort', 'number'), $page, self::PER_PAGE);

        $storeState = $this->cards->findStoreState($game);
        $quantities = $this->entries->sumQuantitiesByCard($user, $game);
        $inList = $list?->type === CardListType::Collection
            ? $this->entries->sumQuantitiesByListAndCard($user, CardListType::Collection, $game)[$list->id->toRfc4122()] ?? []
            : null; // A wishlist's cards keep the copies over all collections

        $cards = $this->cards->findCards($game, $result['ids']);
        $entries = [];
        foreach ($result['ids'] as $id) {
            $state = $quantities[$id->toRfc4122()] ?? [];
            if ($inList !== null) {
                $state[CardListType::Collection->value] = $inList[$id->toRfc4122()] ?? 0; // The copies in the list
            }
            $entries[] = $this->cards->normalizeEntry($cards[$id->toRfc4122()], $storeState, $this->userState($state));
        }

        return new JsonResponse(['total' => $result['total'], 'page' => $page, 'perPage' => self::PER_PAGE, 'cards' => $entries]);
    }

    /**
     * What the catalog of $game can be filtered on: its sets (newest first), rarities and artists.
     * With `?list=<id>`, only those of the cards in that collection or wishlist.
     */
    #[Route('/catalog/{game}/filters', requirements: ['game' => new EnumRequirement(Game::class)], methods: ['GET'])]
    public function catalogFilters(#[CurrentUser] User $user, Game $game, Request $request): JsonResponse
    {
        return new JsonResponse($this->cards->findCatalogFilters($game, $this->findList($user, $request)));
    }

    /**
     * The user's collection or wishlist named by `?list=<id>`; null without one.
     */
    private function findList(User $user, Request $request): ?CardList
    {
        $id = $request->query->getString('list');
        if ($id === '') {
            return null;
        }

        $list = Uuid::isValid($id) ? $this->lists->find(Uuid::fromString($id)) : null;
        if (!$list instanceof CardList || !$list->user->id->equals($user->id)) {
            throw new NotFoundHttpException("No list with id $id.");
        }

        return $list;
    }

    /**
     * One card of any game.
     */
    #[Route('/cards/{id}', requirements: ['id' => Requirement::UUID], methods: ['GET'])]
    public function card(#[CurrentUser] User $user, string $id): JsonResponse
    {
        $card = $this->findCard($id);
        $storeState = $this->cards->findStoreState($card->tcg, $card->id);
        $quantities = $this->entries->sumQuantitiesByCard($user, $card->tcg, $card->id);

        return new JsonResponse($this->cards->normalizeEntry($card, $storeState, $this->userState($quantities[$card->id->toRfc4122()] ?? [])));
    }

    /**
     * Where the user has a card: `{"lists": [{"listId", "type", "finish", "quantity"}]}`, one per
     * list and finish, oldest list first.
     */
    #[Route('/cards/{id}/lists', requirements: ['id' => Requirement::UUID], methods: ['GET'])]
    public function lists(#[CurrentUser] User $user, string $id): JsonResponse
    {
        $card = $this->findCard($id);

        return new JsonResponse(['lists' => array_map(static fn (array $row): array => [
            ...$row,
            'type' => $row['type']->value,
        ], $this->entries->findByCard($user, $card->tcg, $card->id))]);
    }

    /**
     * Market data for a card: the finishes it comes in, how many users have / want it, and its
     * store listings in stock, cheapest first: one per finish and condition.
     *
     * There's no price history yet: `history` is today's price for each of the last 30 days, and
     * `change7d` 0.
     */
    #[Route('/cards/{id}/market', requirements: ['id' => Requirement::UUID], methods: ['GET'])]
    public function market(string $id): JsonResponse
    {
        $card = $this->findCard($id);
        $listings = $this->cards->findListings($card);
        $users = $this->entries->countUsersByType($card->tcg, $card->id);
        $price = $listings === [] ? 0 : $listings[0]->price;

        return new JsonResponse([
            'finishes' => $this->cards->findFinishes($card, $listings),
            'change7d' => 0,
            'history' => array_fill(0, 30, $price),
            'have' => $users[CardListType::Collection->value] ?? 0,
            'want' => $users[CardListType::Wishlist->value] ?? 0,
            'listings' => array_map(static fn (CardListingCondition $k): array => [
                'productId' => $k->listing->productId, // 2HG's id of the product: its cart takes it with the condition
                'finish' => $k->listing->finish,
                'condition' => $k->condition, // As the shop names it
                'price' => $k->price,
                'stock' => $k->stock,
            ], $listings),
        ]);
    }

    private function findCard(string $id): Card
    {
        return $this->cards->findCard(Uuid::fromString($id)) ?? throw new NotFoundHttpException("No card with id $id.");
    }

    /**
     * @param array<string, int> $quantities the card's entry from {@see CardListEntryRepository::sumQuantitiesByCard()}
     *
     * @return array{owned: int, wishlisted: bool}
     */
    private function userState(array $quantities): array
    {
        return [
            'owned' => $quantities[CardListType::Collection->value] ?? 0,
            'wishlisted' => isset($quantities[CardListType::Wishlist->value]),
        ];
    }
}
