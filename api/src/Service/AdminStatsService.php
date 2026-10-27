<?php declare(strict_types=1);

namespace App\Service;

use App\ApiResource\Card;
use App\Enum\CardListType;
use App\Enum\Game;
use DateTimeImmutable;
use Doctrine\DBAL\ArrayParameterType;
use Doctrine\DBAL\Connection;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\Uid\Uuid;
use function array_map;
use function array_keys;
use function is_numeric;
use function is_scalar;
use function is_string;

/**
 * Numbers for the admin dashboard. Raw SQL throughout: these are aggregates over whole tables,
 * nothing here needs hydrated entities except the handful of cards shown in the top lists.
 *
 * "Collected / wishlisted in the past week" means the card was *added* to a list in that window
 * (card_list_entry.created_at); later quantity bumps don't count as a new add.
 */
final readonly class AdminStatsService
{
    public const array PERIODS = [
        'week' => ['label' => 'Week', 'since' => '-7 days'],
        'month' => ['label' => 'Month', 'since' => '-30 days'],
        'all' => ['label' => 'All time', 'since' => null],
    ];

    private const int TOP_LIMIT = 10;
    private const int DAILY_DAYS = 30;

    public function __construct(
        private Connection $db,
        private EntityManagerInterface $entityManager,
    ) {}

    /**
     * @return array{users: int, newUsers: int, newUsersPrevious: int, activeUsers: int, collectedCopies: int,
     *     collectedCards: int, wishlistedCopies: int, listings: int, listingsInStock: int, unlinked: int}
     */
    public function totals(): array
    {
        $weekAgo = new DateTimeImmutable('-7 days');
        $twoWeeksAgo = new DateTimeImmutable('-14 days');

        $users = $this->db->fetchAssociative(
            'SELECT COUNT(*) AS users,
                    SUM(created_at >= :week) AS new_users,
                    SUM(created_at >= :twoWeeks AND created_at < :week) AS new_users_previous,
                    SUM(last_seen_at >= :week) AS active_users
             FROM app_user',
            ['week' => $this->sqlDate($weekAgo), 'twoWeeks' => $this->sqlDate($twoWeeksAgo)],
        ) ?: [];

        $lists = $this->db->fetchAssociative(
            'SELECT SUM(CASE WHEN l.type = :collection THEN e.quantity ELSE 0 END) AS collected_copies,
                    COUNT(DISTINCT CASE WHEN l.type = :collection THEN CONCAT(e.game, HEX(e.card_id)) END) AS collected_cards,
                    SUM(CASE WHEN l.type = :wishlist THEN e.quantity ELSE 0 END) AS wishlisted_copies
             FROM card_list_entry e JOIN card_list l ON l.id = e.list_id',
            ['collection' => CardListType::Collection->value, 'wishlist' => CardListType::Wishlist->value],
        ) ?: [];

        $listings = $this->db->fetchAssociative(
            'SELECT COUNT(*) AS listings,
                    SUM(EXISTS(SELECT 1 FROM product_listing_condition k WHERE k.listing_id = l.id AND k.stock > 0)) AS in_stock
             FROM product_listing l',
        ) ?: [];

        return [
            'users' => self::int($users['users'] ?? 0),
            'newUsers' => self::int($users['new_users'] ?? 0),
            'newUsersPrevious' => self::int($users['new_users_previous'] ?? 0),
            'activeUsers' => self::int($users['active_users'] ?? 0),
            'collectedCopies' => self::int($lists['collected_copies'] ?? 0),
            'collectedCards' => self::int($lists['collected_cards'] ?? 0),
            'wishlistedCopies' => self::int($lists['wishlisted_copies'] ?? 0),
            'listings' => self::int($listings['listings'] ?? 0),
            'listingsInStock' => self::int($listings['in_stock'] ?? 0),
            'unlinked' => self::int($this->db->fetchOne('SELECT COUNT(*) FROM product_unmatched')),
        ];
    }

    /**
     * Top cards of a list type for every period in {@see self::PERIODS}, ranked by how many users
     * have them (then by copies).
     *
     * @return array<string, list<array{game: string, cardId: string, card: ?Card, users: int, copies: int}>>
     */
    public function topCards(CardListType $type): array
    {
        $result = [];
        foreach (self::PERIODS as $key => ['since' => $since]) {
            $rows = $this->db->fetchAllAssociative(
                'SELECT e.game, e.card_id, COUNT(DISTINCT l.user_id) AS users, SUM(e.quantity) AS copies
                 FROM card_list_entry e JOIN card_list l ON l.id = e.list_id
                 WHERE l.type = :type' . ($since !== null ? ' AND e.created_at >= :since' : '') . '
                 GROUP BY e.game, e.card_id
                 ORDER BY users DESC, copies DESC, MAX(e.created_at) DESC, e.card_id
                 LIMIT ' . self::TOP_LIMIT,
                ['type' => $type->value] + ($since !== null ? ['since' => $this->sqlDate(new DateTimeImmutable($since))] : []),
            );

            $result[$key] = array_map(static fn (array $row): array => [
                'game' => self::string($row['game']),
                'cardId' => is_string($row['card_id']) ? Uuid::fromBinary($row['card_id'])->toRfc4122() : '',
                'card' => null,
                'users' => self::int($row['users']),
                'copies' => self::int($row['copies']),
            ], $rows);
        }

        return $this->attachCards($result);
    }

    /**
     * Collected copies per game, largest first.
     *
     * @return list<array{label: string, value: int}>
     */
    public function collectedPerGame(): array
    {
        $rows = $this->db->fetchAllAssociative(
            'SELECT e.game, SUM(e.quantity) AS copies
             FROM card_list_entry e JOIN card_list l ON l.id = e.list_id
             WHERE l.type = :type
             GROUP BY e.game ORDER BY copies DESC',
            ['type' => CardListType::Collection->value],
        );

        return array_map(static fn (array $row): array => ['label' => self::string($row['game']), 'value' => self::int($row['copies'])], $rows);
    }

    /**
     * New users per day over the last {@see self::DAILY_DAYS} days, oldest first, zero-filled.
     *
     * @return list<array{date: DateTimeImmutable, value: int}>
     */
    public function newUsersPerDay(): array
    {
        return $this->daily(
            'SELECT DATE(created_at) AS day, COUNT(*) AS c FROM app_user WHERE created_at >= :since GROUP BY day',
        );
    }

    /**
     * Cards added to collections per day over the last {@see self::DAILY_DAYS} days, oldest first.
     *
     * @return list<array{date: DateTimeImmutable, value: int}>
     */
    public function collectionAddsPerDay(): array
    {
        return $this->daily(
            'SELECT DATE(e.created_at) AS day, COUNT(*) AS c
             FROM card_list_entry e JOIN card_list l ON l.id = e.list_id
             WHERE l.type = :type AND e.created_at >= :since GROUP BY day',
            ['type' => CardListType::Collection->value],
        );
    }

    /**
     * @param array<string, string> $params
     * @return list<array{date: DateTimeImmutable, value: int}>
     */
    private function daily(string $sql, array $params = []): array
    {
        $today = new DateTimeImmutable('today');
        $first = $today->modify('-' . (self::DAILY_DAYS - 1) . ' days');

        $counts = [];
        foreach ($this->db->fetchAllAssociative($sql, $params + ['since' => $this->sqlDate($first)]) as $row) {
            $counts[self::string($row['day'])] = self::int($row['c']);
        }

        $days = [];
        for ($day = $first; $day <= $today; $day = $day->modify('+1 day')) {
            $days[] = ['date' => $day, 'value' => $counts[$day->format('Y-m-d')] ?? 0];
        }

        return $days;
    }

    /**
     * Loads the cards for every top-list row in one query per game.
     *
     * @param array<string, list<array{game: string, cardId: string, card: ?Card, users: int, copies: int}>> $lists
     * @return array<string, list<array{game: string, cardId: string, card: ?Card, users: int, copies: int}>>
     */
    private function attachCards(array $lists): array
    {
        $idsPerGame = [];
        foreach ($lists as $rows) {
            foreach ($rows as $row) {
                $idsPerGame[$row['game']][$row['cardId']] = true;
            }
        }

        $cards = [];
        foreach ($idsPerGame as $gameValue => $ids) {
            $game = Game::tryFrom($gameValue);
            if ($game === null) {
                continue;
            }

            /** @var list<Card> $found */
            $found = $this->entityManager->createQueryBuilder()
                ->select('c', 's')
                ->from($game->cardClass(), 'c')
                ->join('c.set', 's')
                ->where('c.id IN (:ids)')
                ->setParameter('ids', array_map(static fn (string $id): string => Uuid::fromString($id)->toBinary(), array_keys($ids)), ArrayParameterType::BINARY)
                ->getQuery()
                ->getResult();

            foreach ($found as $card) {
                $cards[$gameValue][$card->id->toRfc4122()] = $card;
            }
        }

        return array_map(
            static fn (array $rows): array => array_map(
                static fn (array $row): array => ['card' => $cards[$row['game']][$row['cardId']] ?? null] + $row,
                $rows,
            ),
            $lists,
        );
    }

    /** Aggregates come back from the driver as int, numeric string or null (empty SUM). */
    private static function int(mixed $value): int
    {
        return is_numeric($value) ? (int) $value : 0;
    }

    private static function string(mixed $value): string
    {
        return is_scalar($value) ? (string) $value : '';
    }

    private function sqlDate(DateTimeImmutable $date): string
    {
        return $date->format('Y-m-d H:i:s');
    }
}
