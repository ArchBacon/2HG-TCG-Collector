<?php declare(strict_types=1);

namespace App\Service;

use App\Entity\CardPrice;
use App\Enum\Game;
use DateTimeImmutable;
use Doctrine\DBAL\ArrayParameterType;
use Doctrine\DBAL\Connection;
use Doctrine\DBAL\ParameterType;
use Symfony\Component\Uid\Uuid;
use function array_filter;
use function array_keys;
use function array_map;
use function array_merge;
use function array_values;
use function count;
use function implode;
use function number_format;
use function sprintf;
use const DATE_ATOM;

/**
 * Keeps cards' market prices ({@see CardPrice}) up to date during an import: the importer
 * {@see add()}s each card's prices as it goes, and {@see flush()}es along with its own flushes.
 * A flush writes them in batches, and drops the prices those cards no longer have (a finish or a
 * source the card data stopped listing), so each card's prices are exactly what the last sync saw.
 *
 * @phpstan-type Price array{source: string, finish: string, currency: string, price: float, updatedAt?: ?DateTimeImmutable}
 */
final class CardPriceStore
{
    private const int BATCH_SIZE = 500;

    /** @var array<string, array{game: string, prices: list<Price>}> by card id (binary) */
    private array $pending = [];

    public function __construct(private readonly Connection $connection) {}

    /**
     * Sets $cardId's prices to $prices (an empty list removes them all), at the next flush. Prices
     * of 0 or less, as sources give for "none", are left out.
     *
     * @param list<Price> $prices
     */
    public function add(Game $game, Uuid $cardId, array $prices): void
    {
        $this->pending[$cardId->toBinary()] = [
            'game' => $game->value,
            'prices' => array_values(array_filter($prices, static fn (array $p): bool => $p['price'] > 0)),
        ];
        if (count($this->pending) >= self::BATCH_SIZE) {
            $this->flush();
        }
    }

    public function flush(): void
    {
        if ($this->pending === []) {
            return;
        }
        $pending = $this->pending;
        $this->pending = [];
        $now = new DateTimeImmutable();
        $syncedAt = $now->format('Y-m-d H:i:s');

        $this->connection->transactional(function (Connection $db) use ($pending, $now, $syncedAt): void {
            $values = [];
            $params = [];
            foreach ($pending as $cardId => ['game' => $game, 'prices' => $prices]) {
                foreach ($prices as $price) {
                    $values[] = '(?, ?, ?, ?, ?, ?, ?, ?)';
                    $params = array_merge($params, [
                        $game, $cardId, $price['source'], $price['finish'], $price['currency'],
                        number_format($price['price'], 2, '.', ''),
                        ($price['updatedAt'] ?? null)?->format('Y-m-d H:i:s') ?? $syncedAt,
                        $syncedAt,
                    ]);
                }
            }

            // synced_at marks what this sync wrote, so what it didn't can go below
            if ($values !== []) {
                $db->executeStatement(sprintf(
                    'INSERT INTO card_price (game, card_id, source, finish, currency, price, updated_at, synced_at) VALUES %s'
                    . ' ON DUPLICATE KEY UPDATE game = VALUES(game), currency = VALUES(currency), price = VALUES(price),'
                    . ' updated_at = VALUES(updated_at), synced_at = VALUES(synced_at)',
                    implode(', ', $values),
                ), $params);
            }

            $db->executeStatement(
                'DELETE FROM card_price WHERE card_id IN (?) AND synced_at < ?',
                [array_keys($pending), $now->format('Y-m-d H:i:s')],
                [ArrayParameterType::BINARY, ParameterType::STRING],
            );
        });
    }

    /**
     * $cardId's prices, by finish and source.
     *
     * @return list<array{source: string, finish: string, currency: string, price: float, updatedAt: string}>
     */
    public function find(Uuid $cardId): array
    {
        /** @var list<array{source: string, finish: string, currency: string, price: string, updated_at: string}> $rows */
        $rows = $this->connection->fetchAllAssociative(
            'SELECT source, finish, currency, price, updated_at FROM card_price WHERE card_id = ? ORDER BY finish, source',
            [$cardId->toBinary()],
        );

        return array_map(static fn (array $row): array => [
            'source' => $row['source'],
            'finish' => $row['finish'],
            'currency' => $row['currency'],
            'price' => (float) $row['price'],
            'updatedAt' => new DateTimeImmutable($row['updated_at'])->format(DATE_ATOM),
        ], $rows);
    }
}
