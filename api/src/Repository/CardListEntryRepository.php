<?php declare(strict_types=1);

namespace App\Repository;

use App\Entity\CardList;
use App\Entity\CardListEntry;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
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
