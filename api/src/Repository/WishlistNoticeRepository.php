<?php declare(strict_types=1);

namespace App\Repository;

use App\Entity\WishlistNotice;
use App\Enum\CardListType;
use App\Enum\Game;
use DateTimeImmutable;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\DBAL\ArrayParameterType;
use Doctrine\Persistence\ManagerRegistry;
use Symfony\Component\Uid\Uuid;

use function array_map;

/**
 * @extends ServiceEntityRepository<WishlistNotice>
 */
final class WishlistNoticeRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, WishlistNotice::class);
    }

    /**
     * Records a pending notice for every user who has one of $cardIds of $game on a wishlist (any
     * finish), for $day. A user already noticed of that card that day is skipped (the unique
     * key), so recording a card twice in a day is harmless. Returns the number of notices added.
     *
     * One INSERT ... SELECT, so a stock update with many cards stays a few queries.
     *
     * @param list<Uuid> $cardIds
     */
    public function recordInStock(Game $game, array $cardIds, DateTimeImmutable $day): int
    {
        if ($cardIds === []) {
            return 0;
        }

        return (int) $this->getEntityManager()->getConnection()->executeStatement(
            <<<'SQL'
                INSERT IGNORE INTO wishlist_notice (user_id, game, card_id, notice_day, created_at)
                SELECT DISTINCT l.user_id, e.game, e.card_id, :day, :now
                FROM card_list_entry e
                JOIN card_list l ON l.id = e.list_id
                WHERE l.type = :type AND e.game = :game AND e.card_id IN (:ids)
                SQL,
            [
                'day' => $day->format('Y-m-d'),
                'now' => new DateTimeImmutable()->format('Y-m-d H:i:s'),
                'type' => CardListType::Wishlist->value,
                'game' => $game->value,
                'ids' => array_map(static fn (Uuid $id): string => $id->toBinary(), $cardIds),
            ],
            ['ids' => ArrayParameterType::BINARY],
        );
    }

    /**
     * The notices not built into a push yet, with their users, grouped by user (in id order).
     *
     * @return list<WishlistNotice>
     */
    public function findPending(): array
    {
        /** @var list<WishlistNotice> */
        return $this->createQueryBuilder('n')
            ->addSelect('u')
            ->join('n.user', 'u')
            ->where('n.push IS NULL')
            ->orderBy('u.id')
            ->addOrderBy('n.id')
            ->getQuery()
            ->getResult();
    }
}
