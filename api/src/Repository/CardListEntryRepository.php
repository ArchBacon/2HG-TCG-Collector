<?php declare(strict_types=1);

namespace App\Repository;

use App\Entity\CardList;
use App\Entity\CardListEntry;
use App\Entity\User;
use App\Enum\CardListType;
use App\Enum\Game;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\ORM\Query\Expr\Join;
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
     * @return array<string, array<string, int>>
     */
    public function sumQuantitiesByTypeAndGame(User $user): array
    {
        /** @var list<array{type: CardListType, game: string, total: int|string}> $rows */
        $rows = $this->createQueryBuilder('e')
            ->select('l.type AS type', 'e.game AS game', 'SUM(e.quantity) AS total')
            ->join('e.list', 'l')
            ->where('l.user = :user')
            ->setParameter('user', $user->id, 'uuid')
            ->groupBy('l.type', 'e.game')
            ->getQuery()
            ->getArrayResult();

        $totals = [];
        foreach ($rows as $row) {
            $totals[$row['type']->value][$row['game']] = (int) $row['total'];
        }

        return $totals;
    }

    /**
     * Number of distinct cards per set of $game that appear in any of the user's collections,
     * keyed by set id (RFC 4122). Finishes and copies of the same card count once, so the result
     * can be compared against a set's card count. Sets without collected cards are left out.
     *
     * @return array<string, int>
     */
    public function countCollectedCardsBySet(User $user, Game $game): array
    {
        /** @var list<array{setId: Uuid, total: int|string}> $rows */
        $rows = $this->createQueryBuilder('e')
            ->select('IDENTITY(c.set) AS setId', 'COUNT(DISTINCT e.cardId) AS total')
            ->join('e.list', 'l')
            ->join($game->cardClass(), 'c', Join::WITH, 'c.id = e.cardId')
            ->where('l.user = :user')
            ->andWhere('l.type = :type')
            ->andWhere('e.game = :game')
            ->setParameter('user', $user->id, 'uuid')
            ->setParameter('type', CardListType::Collection->value)
            ->setParameter('game', $game->value)
            ->groupBy('c.set')
            ->getQuery()
            ->getArrayResult();

        $counts = [];
        foreach ($rows as $row) {
            $counts[Uuid::fromString((string) $row['setId'])->toRfc4122()] = (int) $row['total'];
        }

        return $counts;
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
