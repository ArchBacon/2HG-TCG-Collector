<?php declare(strict_types=1);

namespace App\Repository;

use App\Entity\CardList;
use App\Entity\CardListEntry;
use App\Entity\User;
use App\Enum\CardListType;
use App\Enum\Game;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\ORM\Query\Expr\Join;
use Doctrine\ORM\QueryBuilder;
use Doctrine\Persistence\ManagerRegistry;
use Symfony\Component\Uid\Uuid;

/**
 * @extends ServiceEntityRepository<CardListEntry>
 */
final class CardListEntryRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, CardListEntry::class);
    }

    /**
     * Total quantity per list type and game across all of a user's lists, e.g.
     * `['collection' => ['mtg' => 12], 'wishlist' => ['pokemon' => 3]]`. Games without entries
     * are left out.
     *
     * @param ?CardList $list only this list
     *
     * @return array<string, array<string, int>>
     */
    public function sumQuantitiesByTypeAndGame(User $user, ?CardList $list = null): array
    {
        $query = $this->createQueryBuilder('e')
            ->select('l.type AS type', 'e.game AS game', 'SUM(e.quantity) AS total')
            ->join('e.list', 'l')
            ->where('l.user = :user')
            ->setParameter('user', $user->id, 'uuid')
            ->groupBy('l.type', 'e.game');
        self::onlyList($query, $list);

        /** @var list<array{type: CardListType, game: string, total: int|string}> $rows */
        $rows = $query->getQuery()->getArrayResult();

        $totals = [];
        foreach ($rows as $row) {
            $totals[$row['type']->value][$row['game']] = (int) $row['total'];
        }

        return $totals;
    }

    /**
     * Every card + finish in any of the user's lists of $type, merged across those lists:
     * quantities added up, and `addedAt` the first time it was added to one of them. Newest first.
     *
     * @param ?Game $game only this game's cards
     * @param ?CardList $list only this list
     *
     * @return list<array{game: string, cardId: Uuid, finish: string, quantity: int, addedAt: \DateTimeImmutable}>
     */
    public function findMergedByType(User $user, CardListType $type, ?Game $game = null, ?CardList $list = null): array
    {
        $query = $this->createQueryBuilder('e')
            ->select('e.game AS game', 'e.cardId AS cardId', 'e.finish AS finish', 'SUM(e.quantity) AS quantity', 'MIN(e.createdAt) AS addedAt')
            ->join('e.list', 'l')
            ->where('l.user = :user')
            ->andWhere('l.type = :type')
            ->setParameter('user', $user->id, 'uuid')
            ->setParameter('type', $type->value)
            ->groupBy('e.game', 'e.cardId', 'e.finish')
            ->orderBy('addedAt', 'DESC');
        if ($game !== null) {
            $query->andWhere('e.game = :game')->setParameter('game', $game->value);
        }
        self::onlyList($query, $list);

        /** @var list<array{game: string, cardId: Uuid, finish: string, quantity: int|string, addedAt: string}> $rows */
        $rows = $query->getQuery()->getArrayResult();

        return array_map(static fn (array $row): array => [
            'game' => $row['game'],
            'cardId' => $row['cardId'],
            'finish' => $row['finish'],
            'quantity' => (int) $row['quantity'],
            'addedAt' => new \DateTimeImmutable($row['addedAt']),
        ], $rows);
    }

    /**
     * Copies of each of $game's cards across the user's lists, per list type and keyed by card id
     * (RFC 4122), e.g. `['<id>' => ['collection' => 3, 'wishlist' => 1]]`. Cards on none of the
     * user's lists are left out.
     *
     * @param ?Uuid $cardId only this card
     *
     * @return array<string, array<string, int>>
     */
    public function sumQuantitiesByCard(User $user, Game $game, ?Uuid $cardId = null): array
    {
        $query = $this->createQueryBuilder('e')
            ->select('e.cardId AS cardId', 'l.type AS type', 'SUM(e.quantity) AS total')
            ->join('e.list', 'l')
            ->where('l.user = :user')
            ->andWhere('e.game = :game')
            ->setParameter('user', $user->id, 'uuid')
            ->setParameter('game', $game->value)
            ->groupBy('e.cardId', 'l.type');
        if ($cardId !== null) {
            $query->andWhere('e.cardId = :card')->setParameter('card', $cardId, 'uuid');
        }

        /** @var list<array{cardId: Uuid, type: CardListType, total: int|string}> $rows */
        $rows = $query->getQuery()->getArrayResult();

        $totals = [];
        foreach ($rows as $row) {
            $totals[$row['cardId']->toRfc4122()][$row['type']->value] = (int) $row['total'];
        }

        return $totals;
    }

    /**
     * How many users have a card on a list, per list type, e.g. `['collection' => 12, 'wishlist' => 4]`.
     * Every user counts once, however many copies or lists they have it on.
     *
     * @return array<string, int>
     */
    public function countUsersByType(Game $game, Uuid $cardId): array
    {
        /** @var list<array{type: CardListType, total: int|string}> $rows */
        $rows = $this->createQueryBuilder('e')
            ->select('l.type AS type', 'COUNT(DISTINCT l.user) AS total')
            ->join('e.list', 'l')
            ->where('e.game = :game')
            ->andWhere('e.cardId = :card')
            ->setParameter('game', $game->value)
            ->setParameter('card', $cardId, 'uuid')
            ->groupBy('l.type')
            ->getQuery()
            ->getArrayResult();

        $counts = [];
        foreach ($rows as $row) {
            $counts[$row['type']->value] = (int) $row['total'];
        }

        return $counts;
    }

    /**
     * Number of distinct cards per set of $game that appear in any of the user's collections,
     * keyed by set id (RFC 4122). Finishes and copies of the same card count once, so the result
     * can be compared against a set's card count. Sets without collected cards are left out.
     *
     * @param ?CardList $list only this collection
     *
     * @return array<string, int>
     */
    public function countCollectedCardsBySet(User $user, Game $game, ?CardList $list = null): array
    {
        $query = $this->createQueryBuilder('e')
            ->select('IDENTITY(c.set) AS setId', 'COUNT(DISTINCT e.cardId) AS total')
            ->join('e.list', 'l')
            ->join($game->cardClass(), 'c', Join::WITH, 'c.id = e.cardId')
            ->where('l.user = :user')
            ->andWhere('l.type = :type')
            ->andWhere('e.game = :game')
            ->setParameter('user', $user->id, 'uuid')
            ->setParameter('type', CardListType::Collection->value)
            ->setParameter('game', $game->value)
            ->groupBy('c.set');
        self::onlyList($query, $list);

        /** @var list<array{setId: Uuid, total: int|string}> $rows */
        $rows = $query->getQuery()->getArrayResult();

        $counts = [];
        foreach ($rows as $row) {
            $counts[Uuid::fromString((string) $row['setId'])->toRfc4122()] = (int) $row['total'];
        }

        return $counts;
    }

    /**
     * Copies per card of $game in each of the user's lists of $type, keyed by list id and card id
     * (both RFC 4122): `['<list>' => ['<card>' => 3]]`, finishes added up. Lists without cards of
     * $game are left out.
     *
     * @return array<string, array<string, int>>
     */
    public function sumQuantitiesByListAndCard(User $user, CardListType $type, Game $game): array
    {
        /** @var list<array{listId: string, cardId: Uuid, total: int|string}> $rows */
        $rows = $this->createQueryBuilder('e')
            ->select('IDENTITY(e.list) AS listId', 'e.cardId AS cardId', 'SUM(e.quantity) AS total')
            ->join('e.list', 'l')
            ->where('l.user = :user')
            ->andWhere('l.type = :type')
            ->andWhere('e.game = :game')
            ->setParameter('user', $user->id, 'uuid')
            ->setParameter('type', $type->value)
            ->setParameter('game', $game->value)
            ->groupBy('e.list', 'e.cardId')
            ->getQuery()
            ->getArrayResult();

        $totals = [];
        foreach ($rows as $row) {
            $totals[Uuid::fromString($row['listId'])->toRfc4122()][$row['cardId']->toRfc4122()] = (int) $row['total'];
        }

        return $totals;
    }

    /**
     * Where the user has a card: one row per list and finish, oldest list first.
     *
     * @return list<array{listId: string, type: CardListType, finish: string, quantity: int}>
     */
    public function findByCard(User $user, Game $game, Uuid $cardId): array
    {
        /** @var list<array{listId: string, type: CardListType, finish: string, quantity: int|string}> $rows */
        $rows = $this->createQueryBuilder('e')
            ->select('IDENTITY(e.list) AS listId', 'l.type AS type', 'e.finish AS finish', 'e.quantity AS quantity')
            ->join('e.list', 'l')
            ->where('l.user = :user')
            ->andWhere('e.game = :game')
            ->andWhere('e.cardId = :card')
            ->setParameter('user', $user->id, 'uuid')
            ->setParameter('game', $game->value)
            ->setParameter('card', $cardId, 'uuid')
            ->orderBy('l.createdAt', 'ASC')
            ->addOrderBy('l.name', 'ASC')
            ->addOrderBy('e.finish', 'ASC')
            ->getQuery()
            ->getArrayResult();

        return array_map(static fn (array $row): array => [
            'listId' => Uuid::fromString($row['listId'])->toRfc4122(),
            'type' => $row['type'],
            'finish' => $row['finish'],
            'quantity' => (int) $row['quantity'],
        ], $rows);
    }

    /**
     * The quantity of a card + finish in a list; 0 when it isn't in it.
     */
    public function quantityIn(CardList $list, string $game, Uuid $cardId, string $finish): int
    {
        // From the database, not the entity map: applyDelta() changes it in raw SQL
        $quantity = $this->getEntityManager()->getConnection()->fetchOne(
            'SELECT quantity FROM card_list_entry WHERE list_id = :list AND game = :game AND card_id = :card AND finish = :finish',
            ['list' => $list->id->toBinary(), 'game' => $game, 'card' => $cardId->toBinary(), 'finish' => $finish],
        );

        return is_numeric($quantity) ? (int) $quantity : 0;
    }

    /**
     * @param QueryBuilder $query with the entries as `e`
     */
    private static function onlyList(QueryBuilder $query, ?CardList $list): void
    {
        if ($list !== null) {
            $query->andWhere('e.list = :list')->setParameter('list', $list->id, 'uuid');
        }
    }

    /**
     * Adds $delta copies (negative to remove) of a card to a list in one atomic upsert, clamped
     * at 0, then deletes the row if nothing is left. Done in raw SQL instead of load/modify/flush
     * so two devices syncing at once can't lose each other's changes.
     */
    public function applyDelta(CardList $list, string $game, Uuid $cardId, string $finish, int $delta): void
    {
        $connection = $this->getEntityManager()->getConnection();
        $params = [
            'list' => $list->id->toBinary(),
            'game' => $game,
            'card' => $cardId->toBinary(),
            'finish' => $finish,
            'delta' => $delta,
            'now' => new \DateTimeImmutable()->format('Y-m-d H:i:s'),
        ];

        // CAST to SIGNED: the column is unsigned, so `quantity + -n` would error before GREATEST applies.
        $connection->executeStatement(
            'INSERT INTO card_list_entry (list_id, game, card_id, finish, quantity, created_at, updated_at)
             VALUES (:list, :game, :card, :finish, GREATEST(:delta, 0), :now, :now)
             ON DUPLICATE KEY UPDATE
                quantity = GREATEST(CAST(quantity AS SIGNED) + :delta, 0),
                updated_at = :now',
            $params,
        );

        $connection->executeStatement(
            'DELETE FROM card_list_entry
             WHERE list_id = :list AND game = :game AND card_id = :card AND finish = :finish AND quantity = 0',
            array_intersect_key($params, array_flip(['list', 'game', 'card', 'finish'])),
        );
    }
}
