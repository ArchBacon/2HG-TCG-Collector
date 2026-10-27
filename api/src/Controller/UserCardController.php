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
     * - `list`: a collection's id, for only the cards in it; `owned` is then the copies in it
     * - `sort`: `number` (set order, newest set first, then number; the default), `priceHigh`,
     *   `priceLow` or `name`
     */
    #[Route('/catalog/{game}', requirements: ['game' => new EnumRequirement(Game::class)], methods: ['GET'])]
    public function catalog(#[CurrentUser] User $user, Game $game, Request $request): JsonResponse
    {
        $query = $request->query;
        $page = max(1, $query->getInt('page', 1));
        $set = $query->getString('set');
        $rarity = $query->getString('rarity');
        $artist = $query->getString('artist');
        $search = trim($query->getString('search'));
        $inList = $this->findListQuantities($user, $game, $request);

        $storeState = $this->cards->findStoreState($game);
        $quantities = $this->entries->sumQuantitiesByCard($user, $game);
        $state = static function (array $row) use ($quantities, $inList): array {
            $state = $quantities[$row['id']->toRfc4122()] ?? [];
            if ($inList !== null) {
                $state[CardListType::Collection->value] = $inList[$row['id']->toRfc4122()] ?? 0; // The copies in the list
            }

            return $state;
        };

        $rows = array_values(array_filter(
            $this->cards->findCatalogRows($game),
            static fn (array $row): bool => ($inList === null || isset($inList[$row['id']->toRfc4122()]))
                && ($set === '' || $row['setCode'] === $set)
                && ($rarity === '' || $row['rarity'] === $rarity)
                && ($artist === '' || $row['artist'] === $artist)
                && (!$query->getBoolean('owned') || isset($state($row)[CardListType::Collection->value]))
                && (!$query->getBoolean('wishlisted') || isset($state($row)[CardListType::Wishlist->value]))
                && (!$query->getBoolean('inStore') || isset($storeState[$row['id']->toRfc4122()]))
                && ($search === '' || mb_stripos($row['name'], $search) !== false),
        ));

        $price = static fn (array $row): float => $storeState[$row['id']->toRfc4122()]['price'] ?? 0;
        match ($query->getString('sort', 'number')) {
            'priceHigh' => usort($rows, static fn (array $a, array $b): int => $price($b) <=> $price($a)),
            'priceLow' => usort($rows, static fn (array $a, array $b): int => $price($a) <=> $price($b)),
            'name' => usort($rows, static fn (array $a, array $b): int => strnatcasecmp($a['name'], $b['name'])),
            default => null, // Already in number order
        };

        $pageRows = array_slice($rows, ($page - 1) * self::PER_PAGE, self::PER_PAGE);
        $cards = $this->cards->findCards($game, array_column($pageRows, 'id'));
        $entries = [];
        foreach ($pageRows as $row) {
            $card = $cards[$row['id']->toRfc4122()];
            $entries[] = $this->cards->normalizeEntry($card, $storeState, $this->userState($state($row)));
        }

        return new JsonResponse(['total' => count($rows), 'page' => $page, 'perPage' => self::PER_PAGE, 'cards' => $entries]);
    }

    /**
     * What the catalog of $game can be filtered on: its sets (newest first), rarities and artists.
     * With `?list=<id>`, only those of the cards in that collection.
     */
    #[Route('/catalog/{game}/filters', requirements: ['game' => new EnumRequirement(Game::class)], methods: ['GET'])]
    public function catalogFilters(#[CurrentUser] User $user, Game $game, Request $request): JsonResponse
    {
        $inList = $this->findListQuantities($user, $game, $request);
        if ($inList === null) {
            return new JsonResponse($this->cards->findCatalogFilters($game));
        }

        $sets = $rarities = $artists = [];
        foreach ($this->cards->findCatalogRows($game) as $row) {
            if (!isset($inList[$row['id']->toRfc4122()])) {
                continue;
            }
            $sets[$row['setCode']] ??= ['code' => $row['setCode'], 'name' => $row['setName']]; // Rows are newest set first
            if ($row['rarity'] !== null && $row['rarity'] !== '') {
                $rarities[$row['rarity']] = true;
            }
            if ($row['artist'] !== null && $row['artist'] !== '') {
                $artists[$row['artist']] = true;
            }
        }
        $rarities = array_map(strval(...), array_keys($rarities));
        $artists = array_map(strval(...), array_keys($artists));
        sort($rarities);
        sort($artists);

        return new JsonResponse(['sets' => array_values($sets), 'rarities' => $rarities, 'artists' => $artists]);
    }

    /**
     * Copies per card (keyed by id, RFC 4122) in the collection named by `?list=<id>`; null without
     * one.
     *
     * @return ?array<string, int>
     */
    private function findListQuantities(User $user, Game $game, Request $request): ?array
    {
        $id = $request->query->getString('list');
        if ($id === '') {
            return null;
        }

        $list = Uuid::isValid($id) ? $this->lists->find(Uuid::fromString($id)) : null;
        if (!$list instanceof CardList || !$list->user->id->equals($user->id) || $list->type !== CardListType::Collection) {
            throw new NotFoundHttpException("No collection with id $id.");
        }

        return $this->entries->sumQuantitiesByListAndCard($user, CardListType::Collection, $game)[$list->id->toRfc4122()] ?? [];
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
