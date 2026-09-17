<?php declare(strict_types=1);

/*
 * ✦ ── AI-GENERATED CODE ────────────────────────────────────────────── ✦
 *   This was written by an AI assistant, not by hand. Beep boop.
 * ✦ ─────────────────────────────────────────────────────────────────── ✦
 */

namespace App\Repository;

use App\Entity\ImageJobQueue;
use App\Enum\ImageJobStatus;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\DBAL\ArrayParameterType;
use Doctrine\Persistence\ManagerRegistry;
use Symfony\Component\Uid\Uuid;

/**
 * @extends ServiceEntityRepository<ImageJobQueue>
 *
 * Almost everything here goes through raw DBAL rather than the ORM: this table is worked by
 * many concurrent processes claiming/updating single rows or small batches at a time, and at
 * hundreds of thousands of rows the per-row entity hydration/unit-of-work overhead the ORM
 * would add isn't worth paying just to run an UPDATE.
 */
final class ImageJobQueueRepository extends ServiceEntityRepository
{
    private const string TABLE = 'image_job_queue';

    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, ImageJobQueue::class);
    }

    /**
     * Atomically claims up to $limit pending rows for $game and returns them.
     *
     * Uses SELECT ... FOR UPDATE SKIP LOCKED rather than a plain UPDATE ... ORDER BY ... LIMIT:
     * the latter range-scans the (game, status, id) index taking gap/next-key locks as it goes,
     * and under enough concurrent callers (WORKER_LIMIT workers hitting this at once) those
     * locks get acquired in different orders and deadlock. SKIP LOCKED sidesteps that entirely
     * — each caller simply skips rows already locked by another transaction instead of
     * blocking on them — and the follow-up UPDATE targets exact ids (point lookups, record
     * locks only), so there's no range-scan lock contention left to deadlock on.
     *
     * @return list<array{id: int, cardId: string, imageUri: ?string}> cardId as an RFC 4122 string
     */
    public function claimBatch(string $game, int $limit, string $token): array
    {
        return $this->retryOnDeadlock(function () use ($game, $limit, $token): array {
            $connection = $this->getEntityManager()->getConnection();
            $now = (new \DateTimeImmutable())->format('Y-m-d H:i:s');

            $connection->beginTransaction();
            try {
                $rows = $connection->fetchAllAssociative(
                    'SELECT id, card_id, image_uri FROM ' . self::TABLE . '
                     WHERE game = :game AND status = :pending
                     ORDER BY id ASC
                     LIMIT ' . max(0, $limit) . '
                     FOR UPDATE SKIP LOCKED',
                    ['game' => $game, 'pending' => ImageJobStatus::Pending->value],
                );

                if ($rows !== []) {
                    $ids = array_map(static function (array $row): int {
                        $id = $row['id'];
                        \assert(\is_int($id) || \is_string($id));

                        return (int) $id;
                    }, $rows);

                    $connection->executeStatement(
                        'UPDATE ' . self::TABLE . '
                         SET status = :running, claimed_by = :token, claimed_at = :now, updated_at = :now
                         WHERE id IN (:ids)',
                        [
                            'running' => ImageJobStatus::Running->value,
                            'token' => $token,
                            'now' => $now,
                            'ids' => $ids,
                        ],
                        ['ids' => ArrayParameterType::INTEGER],
                    );
                }

                $connection->commit();
            } catch (\Throwable $e) {
                $connection->rollBack();
                throw $e;
            }

            return array_map(
                static function (array $row): array {
                    $id = $row['id'];
                    $cardId = $row['card_id'];
                    $imageUri = $row['image_uri'];
                    \assert((\is_int($id) || \is_string($id)) && \is_string($cardId) && ($imageUri === null || \is_string($imageUri)));

                    return [
                        'id' => (int) $id,
                        'cardId' => Uuid::fromBinary($cardId)->toRfc4122(),
                        'imageUri' => $imageUri,
                    ];
                },
                $rows,
            );
        });
    }

    /**
     * Retries on a deadlock/lock-wait-timeout, which InnoDB/Aria expect the application to do
     * — the storage engine rolls back one side of the conflict and surfaces it as an error
     * rather than resolving it itself. A handful of concurrent workers hitting the same table
     * is exactly the scenario this happens in, and a retry after a short random pause almost
     * always succeeds immediately since the conflicting transaction has already released its
     * locks by then.
     *
     * @template T
     * @param callable(): T $fn
     * @return T
     */
    private function retryOnDeadlock(callable $fn, int $maxAttempts = 3): mixed
    {
        $attempt = 0;
        while (true) {
            try {
                return $fn();
            } catch (\Doctrine\DBAL\Exception $e) {
                $isTransient = str_contains($e->getMessage(), 'SQLSTATE[40001]');
                if (!$isTransient || ++$attempt >= $maxAttempts) {
                    throw $e;
                }
                usleep(random_int(50_000, 150_000));
            }
        }
    }

    public function markCompleted(int $id): void
    {
        $this->getEntityManager()->getConnection()->executeStatement(
            'UPDATE ' . self::TABLE . '
             SET status = :status, claimed_by = NULL, claimed_at = NULL, updated_at = :now
             WHERE id = :id',
            [
                'status' => ImageJobStatus::Completed->value,
                'now' => (new \DateTimeImmutable())->format('Y-m-d H:i:s'),
                'id' => $id,
            ],
        );
    }

    /** Retried forever: nothing here caps attempts, it's tracked for observability only. */
    public function markFailed(int $id, string $error): void
    {
        $this->getEntityManager()->getConnection()->executeStatement(
            'UPDATE ' . self::TABLE . '
             SET status = :status, attempts = attempts + 1, last_error = :error,
                 claimed_by = NULL, claimed_at = NULL, updated_at = :now
             WHERE id = :id',
            [
                'status' => ImageJobStatus::Failed->value,
                'error' => $error,
                'now' => (new \DateTimeImmutable())->format('Y-m-d H:i:s'),
                'id' => $id,
            ],
        );
    }

    /**
     * Resets any 'running' (a worker died mid-job) or 'failed' row back to 'pending' for the
     * given games. Called by the master command before working each game — retries happen
     * forever, there's no attempt cap.
     *
     * @param list<string> $games
     */
    public function resetStuck(array $games): int
    {
        if ($games === []) {
            return 0;
        }

        return (int) $this->getEntityManager()->getConnection()->executeStatement(
            'UPDATE ' . self::TABLE . '
             SET status = :pending, claimed_by = NULL, claimed_at = NULL, updated_at = :now
             WHERE game IN (:games) AND status IN (:statuses)',
            [
                'pending' => ImageJobStatus::Pending->value,
                'now' => (new \DateTimeImmutable())->format('Y-m-d H:i:s'),
                'games' => $games,
                'statuses' => [ImageJobStatus::Running->value, ImageJobStatus::Failed->value],
            ],
            [
                'games' => ArrayParameterType::STRING,
                'statuses' => ArrayParameterType::STRING,
            ],
        );
    }

    public function countPending(string $game): int
    {
        $count = $this->getEntityManager()->getConnection()->fetchOne(
            'SELECT COUNT(*) FROM ' . self::TABLE . ' WHERE game = :game AND status = :status',
            ['game' => $game, 'status' => ImageJobStatus::Pending->value],
        );
        \assert(\is_int($count) || \is_string($count));

        return (int) $count;
    }

    /**
     * Overall progress for a game, for the master command's live status display: total across
     * every status (the fixed denominator for this run — enqueueing only happens during card
     * import, never while images are being processed), plus how many are completed/failed so far.
     *
     * @return array{total: int, completed: int, failed: int}
     */
    public function progress(string $game): array
    {
        $rows = $this->getEntityManager()->getConnection()->fetchAllAssociative(
            'SELECT status, COUNT(*) AS c FROM ' . self::TABLE . ' WHERE game = :game GROUP BY status',
            ['game' => $game],
        );

        $total = 0;
        $completed = 0;
        $failed = 0;
        foreach ($rows as $row) {
            $status = $row['status'];
            $count = $row['c'];
            \assert(\is_string($status) && (\is_int($count) || \is_string($count)));
            $count = (int) $count;

            $total += $count;
            if ($status === ImageJobStatus::Completed->value) {
                $completed = $count;
            } elseif ($status === ImageJobStatus::Failed->value) {
                $failed = $count;
            }
        }

        return ['total' => $total, 'completed' => $completed, 'failed' => $failed];
    }

    /**
     * Bulk-upserts a queue row per card id, keyed on the (game, card_id) unique index.
     *
     * By default (a resync) this resets matched rows back to 'pending', including ones that
     * were already 'completed' — the caller wants the image re-downloaded. With
     * $onlyIfMissing, existing rows (whatever their status) are left untouched and only truly
     * new cards get a row — for fast incremental imports that shouldn't re-touch images.
     *
     * @param array<string, ?string> $cardImageUris card id (RFC 4122 string) => source image URL
     *        to download, or null if none is known
     */
    public function enqueueBatch(string $game, array $cardImageUris, bool $onlyIfMissing): void
    {
        if ($cardImageUris === []) {
            return;
        }

        $now = (new \DateTimeImmutable())->format('Y-m-d H:i:s');
        $status = ImageJobStatus::Pending->value;

        $placeholders = [];
        $params = [];
        foreach ($cardImageUris as $cardId => $imageUri) {
            $placeholders[] = '(?, ?, ?, ?, 0, ?, ?)';
            array_push($params, $game, Uuid::fromString($cardId)->toBinary(), $imageUri, $status, $now, $now);
        }

        $verb = $onlyIfMissing ? 'INSERT IGNORE' : 'INSERT';
        $sql = $verb . ' INTO ' . self::TABLE . ' (game, card_id, image_uri, status, attempts, created_at, updated_at)
                VALUES ' . implode(', ', $placeholders);
        if (!$onlyIfMissing) {
            $sql .= ' ON DUPLICATE KEY UPDATE image_uri = VALUES(image_uri), status = VALUES(status), updated_at = VALUES(updated_at)';
        }

        $this->getEntityManager()->getConnection()->executeStatement($sql, $params);
    }
}
