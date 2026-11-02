<?php declare(strict_types=1);

namespace App\Service;

use App\ApiResource\Card;
use App\ApiResource\Set;
use App\Entity\CardList;
use App\Entity\CardListEntry;
use App\Entity\CardListingCondition;
use App\Entity\User;
use App\Enum\CardListType;
use App\Enum\Game;
use App\Games\MTG\Entity\Card as MtgCard;
use App\Games\Pokemon\Entity\Card as PokemonCard;
use DateTimeImmutable;
use Doctrine\DBAL\ArrayParameterType;
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\QueryBuilder;
use Symfony\Component\Uid\Uuid;

/**
 * Looks up cards and their store state for the user endpoints, and turns them into the JSON the
 * app reads: `{card: {...}, price, inStore, isNew}` plus whatever user state the endpoint adds.
 */
final readonly class UserCardService
{
    /** How long a card counts as new after it was first listed in the store. */
    private const string NEW_FOR = '-14 days';

    public function __construct(private EntityManagerInterface $entityManager) {}

    /**
     * One page of $game's cards that pass $filters, as ids in $sort order, and how many pass in
     * total. Filtered, sorted and paged by the database, so only the page itself is loaded.
     *
     * Sorts: `number` (set order, newest set first, then number), `priceHigh` / `priceLow` (lowest
     * price in stock; cards not in stock last / first), `name`. Ties keep `number` order.
     *
     * @param array{set: string, rarity: string, artist: string, search: string, owned: bool, wishlisted: bool, inStore: bool} $filters empty strings and false filter nothing
     * @param ?CardList $list only the cards in this collection or wishlist
     *
     * @return array{total: int, ids: list<Uuid>}
     */
    public function findCatalogPage(Game $game, User $user, ?CardList $list, array $filters, string $sort, int $page, int $perPage): array
    {
        $query = $this->entityManager->createQueryBuilder()
            ->from($game->cardClass(), 'c')
            ->join('c.set', 's');
        if ($list !== null) {
            self::onlyInList($query, $list);
        }
        foreach (['set' => 's.code', 'rarity' => 'c.rarity', 'artist' => 'c.artist'] as $filter => $field) {
            if ($filters[$filter] !== '') {
                $query->andWhere("$field = :$filter")->setParameter($filter, $filters[$filter]);
            }
        }
        if ($filters['search'] !== '') {
            // The column's collation already ignores case
            $query->andWhere('c.name LIKE :search')->setParameter('search', '%' . addcslashes($filters['search'], '%_\\') . '%');
        }
        foreach (['owned' => CardListType::Collection, 'wishlisted' => CardListType::Wishlist] as $filter => $type) {
            if ($filters[$filter]) {
                $query
                    ->andWhere("EXISTS (SELECT {$filter}E.id FROM " . CardListEntry::class . " {$filter}E JOIN {$filter}E.list {$filter}L"
                        . " WHERE {$filter}L.user = :user AND {$filter}L.type = :{$filter}Type AND {$filter}E.cardId = c.id)")
                    ->setParameter('user', $user->id, 'uuid')
                    ->setParameter("{$filter}Type", $type->value);
            }
        }
        if ($filters['inStore']) {
            $query
                ->andWhere('EXISTS (SELECT storeK.id FROM ' . CardListingCondition::class . ' storeK JOIN storeK.listing storeL'
                    . ' WHERE storeL.game = :storeGame AND storeL.cardId = c.id AND storeK.stock > 0)')
                ->setParameter('storeGame', $game->value);
        }

        $total = (int) (clone $query)->select('COUNT(c.id)')->getQuery()->getSingleScalarResult();

        $query->select('c.id AS id');
        if ($sort === 'priceHigh' || $sort === 'priceLow') {
            // MariaDB sorts NULL (not in stock) first ascending and last descending
            $query
                ->addSelect('(SELECT MIN(priceK.price) FROM ' . CardListingCondition::class . ' priceK JOIN priceK.listing priceL'
                    . ' WHERE priceL.game = :priceGame AND priceL.cardId = c.id AND priceK.stock > 0) AS HIDDEN price')
                ->setParameter('priceGame', $game->value)
                ->addOrderBy('price', $sort === 'priceHigh' ? 'DESC' : 'ASC');
        } elseif ($sort === 'name') {
            $query->addOrderBy('c.name', 'ASC');
        }
        $query
            ->addSelect('NATURAL_SORT_KEY(c.number) AS HIDDEN numberKey')
            ->addOrderBy('s.releasedAt', 'DESC')
            ->addOrderBy('s.code', 'ASC')
            ->addOrderBy('numberKey', 'ASC')
            ->addOrderBy('c.id', 'ASC') // Stable pages when everything else ties
            ->setFirstResult(($page - 1) * $perPage)
            ->setMaxResults($perPage);

        /** @var list<array{id: Uuid}> $rows */
        $rows = $query->getQuery()->getArrayResult();

        return ['total' => $total, 'ids' => array_column($rows, 'id')];
    }

    /**
     * The sets of $game, newest first, and the rarities and artists (A to Z) its cards have, to
     * filter the catalog on.
     *
     * @param ?CardList $list only those of the cards in this collection or wishlist
     *
     * @return array{sets: list<array{code: string, name: string}>, rarities: list<string>, artists: list<string>}
     */
    public function findCatalogFilters(Game $game, ?CardList $list = null): array
    {
        if ($list === null) {
            /** @var list<array{code: string, name: string}> $sets */
            $sets = $this->entityManager->createQueryBuilder()
                ->select('s.code AS code', 's.name AS name')
                ->from($game->setClass(), 's')
                ->orderBy('s.releasedAt', 'DESC')
                ->addOrderBy('s.code', 'ASC')
                ->getQuery()
                ->getArrayResult();
        } else {
            $query = $this->entityManager->createQueryBuilder()
                ->select('DISTINCT s.code AS code', 's.name AS name', 's.releasedAt AS releasedAt')
                ->from($game->cardClass(), 'c')
                ->join('c.set', 's')
                ->orderBy('s.releasedAt', 'DESC')
                ->addOrderBy('s.code', 'ASC');
            self::onlyInList($query, $list);
            /** @var list<array{code: string, name: string, releasedAt: ?\DateTimeInterface}> $rows */
            $rows = $query->getQuery()->getArrayResult();
            $sets = array_map(static fn (array $row): array => ['code' => $row['code'], 'name' => $row['name']], $rows);
        }

        $distinct = function (string $field) use ($game, $list): array {
            $query = $this->entityManager->createQueryBuilder()
                ->select("DISTINCT c.$field")
                ->from($game->cardClass(), 'c')
                ->where("c.$field IS NOT NULL")
                ->andWhere("c.$field <> ''")
                ->orderBy("c.$field", 'ASC');
            if ($list !== null) {
                self::onlyInList($query, $list);
            }

            /** @var list<string> */
            return $query->getQuery()->getSingleColumnResult();
        };

        return ['sets' => $sets, 'rarities' => $distinct('rarity'), 'artists' => $distinct('artist')];
    }

    /**
     * Narrows $query (cards as `c`) to the cards in $list.
     */
    private static function onlyInList(QueryBuilder $query, CardList $list): void
    {
        $query
            ->andWhere('EXISTS (SELECT listE.id FROM ' . CardListEntry::class . ' listE WHERE listE.list = :list AND listE.cardId = c.id)')
            ->setParameter('list', $list->id, 'uuid');
    }

    /**
     * $game's cards with the given ids, with their sets, keyed by id (RFC 4122).
     *
     * @param list<Uuid> $ids
     *
     * @return array<string, Card>
     */
    public function findCards(Game $game, array $ids): array
    {
        if ($ids === []) {
            return [];
        }

        /** @var list<Card> $cards */
        $cards = $this->entityManager->createQueryBuilder()
            ->select('c', 's')
            ->from($game->cardClass(), 'c')
            ->join('c.set', 's')
            ->where('c.id IN (:ids)')
            ->setParameter('ids', array_map(static fn (Uuid $id): string => $id->toBinary(), $ids), ArrayParameterType::BINARY)
            ->getQuery()
            ->getResult();

        $byId = [];
        foreach ($cards as $card) {
            $byId[$card->id->toRfc4122()] = $card;
        }

        return $byId;
    }

    /**
     * A card of any game by id. Ids are UUIDs, so they don't clash between the games' tables.
     */
    public function findCard(Uuid $id): ?Card
    {
        foreach (Game::cases() as $game) {
            /** @var ?Card $card */
            $card = $this->entityManager->find($game->cardClass(), $id);
            if ($card !== null) {
                return $card;
            }
        }

        return null;
    }

    /**
     * Store state per card of $game that is in stock, keyed by card id (RFC 4122): the lowest
     * price over its finishes and conditions in stock, and whether it was listed recently. Cards
     * not in stock are left out.
     *
     * @param ?Uuid $cardId only this card
     *
     * @return array<string, array{price: float, isNew: bool}>
     */
    public function findStoreState(Game $game, ?Uuid $cardId = null): array
    {
        $query = $this->entityManager->createQueryBuilder()
            ->select('l.cardId AS cardId', 'MIN(k.price) AS price', 'MIN(l.createdAt) AS listedAt')
            ->from(CardListingCondition::class, 'k')
            ->join('k.listing', 'l')
            ->where('l.game = :game')
            ->andWhere('k.stock > 0')
            ->setParameter('game', $game->value)
            ->groupBy('l.cardId');
        if ($cardId !== null) {
            $query->andWhere('l.cardId = :card')->setParameter('card', $cardId, 'uuid');
        }

        /** @var list<array{cardId: Uuid, price: float|string, listedAt: string}> $rows */
        $rows = $query->getQuery()->getArrayResult();

        $newSince = new DateTimeImmutable(self::NEW_FOR);
        $state = [];
        foreach ($rows as $row) {
            $state[$row['cardId']->toRfc4122()] = [
                'price' => (float) $row['price'],
                'isNew' => new DateTimeImmutable($row['listedAt']) >= $newSince,
            ];
        }

        return $state;
    }

    /**
     * The finishes a card comes in, in its game's own names (MTG: nonfoil/foil/etched; Pokémon:
     * normal/holo/reverse/...): the card's own, plus the ones the shop sells it in (the card data
     * misses some, e.g. reverse holos in older Pokémon sets). `normal` when nothing says.
     *
     * @param list<CardListingCondition> $listings
     *
     * @return list<string>
     */
    public function findFinishes(Card $card, array $listings): array
    {
        $own = $card instanceof MtgCard || $card instanceof PokemonCard ? $card->details->finishes : [];
        $sold = array_map(static fn (CardListingCondition $k): string => $k->listing->finish, $listings);
        $finishes = array_values(array_unique([...$own, ...$sold]));

        return $finishes !== [] ? $finishes : ['normal'];
    }

    /**
     * The conditions of a card in stock, over its finishes, cheapest first.
     *
     * @return list<CardListingCondition>
     */
    public function findListings(Card $card): array
    {
        /** @var list<CardListingCondition> */
        return $this->entityManager->createQueryBuilder()
            ->select('k', 'l')
            ->from(CardListingCondition::class, 'k')
            ->join('k.listing', 'l')
            ->where('l.game = :game')
            ->andWhere('l.cardId = :card')
            ->andWhere('k.stock > 0')
            ->setParameter('game', $card->tcg->value)
            ->setParameter('card', $card->id, 'uuid')
            ->orderBy('k.price', 'ASC')
            ->addOrderBy('k.id', 'ASC')
            ->getQuery()
            ->getResult();
    }

    /**
     * A card entry as the app reads it, with its store state from {@see self::findStoreState()}.
     *
     * @param array<string, array{price: float, isNew: bool}> $storeState
     * @param array<string, mixed> $extra user state to add, e.g. `owned`
     *
     * @return array<string, mixed>
     */
    public function normalizeEntry(Card $card, array $storeState, array $extra = []): array
    {
        $store = $storeState[$card->id->toRfc4122()] ?? null;

        return [
            'card' => $this->normalizeCard($card),
            'price' => $store['price'] ?? 0,
            'inStore' => $store !== null,
            'isNew' => $store['isNew'] ?? false,
            ...$extra,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function normalizeCard(Card $card): array
    {
        return [
            'id' => $card->id->toRfc4122(),
            'tcg' => $card->tcg->value,
            'name' => $card->name,
            'lang' => $card->lang->value,
            'number' => $card->number,
            'rarity' => $card->rarity,
            'artist' => $card->artist,
            'typeLine' => $card->typeLine,
            'images' => $card->images,
            'set' => $this->normalizeSet($card->set),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function normalizeSet(Set $set): array
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
