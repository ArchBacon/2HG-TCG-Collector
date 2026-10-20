<?php declare(strict_types=1);

namespace App\Service;

use App\ApiResource\Card;
use App\Enum\Game;
use Doctrine\DBAL\ArrayParameterType;
use Doctrine\ORM\EntityManagerInterface;
use function array_flip;
use function array_map;
use function array_slice;
use function bin2hex;
use function count;
use function is_string;
use function substr;
use function usort;

/**
 * Lists a game's cards that don't have every image size on disk, for manual upload in the admin.
 *
 * Image availability isn't stored in the DB (see the per-game CardImageAvailabilityListener),
 * so this diffs every card id against one directory scan per size. Fine for an admin page;
 * not something to put on a hot path.
 */
final readonly class MissingCardImageFinder
{
    public function __construct(
        private EntityManagerInterface $entityManager,
        private CardImageService $images,
    ) {}

    /**
     * @return array{total: int, cards: list<Card>}
     */
    public function find(Game $game, int $offset, int $limit): array
    {
        $class = $game->cardClass();
        $table = $this->entityManager->getClassMetadata($class)->getTableName();
        $present = $this->images->idsWithAllSizes($game);

        $missing = [];
        foreach ($this->entityManager->getConnection()->fetchFirstColumn('SELECT id FROM ' . $table . ' ORDER BY name, id') as $binary) {
            if (is_string($binary) && !isset($present[self::toRfc4122($binary)])) {
                $missing[] = $binary;
            }
        }

        $page = array_slice($missing, $offset, $limit);
        if ($page === []) {
            return ['total' => count($missing), 'cards' => []];
        }

        /** @var list<Card> $cards */
        $cards = $this->entityManager->createQueryBuilder()
            ->select('c', 's')
            ->from($class, 'c')
            ->join('c.set', 's')
            ->where('c.id IN (:ids)')
            ->setParameter('ids', $page, ArrayParameterType::BINARY)
            ->getQuery()
            ->getResult();

        // IN () doesn't keep the page order.
        $order = array_flip(array_map(self::toRfc4122(...), $page));
        usort($cards, static fn (Card $a, Card $b): int => $order[$a->id->toRfc4122()] <=> $order[$b->id->toRfc4122()]);

        return ['total' => count($missing), 'cards' => $cards];
    }

    /** Same as Uuid::fromBinary()->toRfc4122(), without building an object for every card. */
    private static function toRfc4122(string $binary): string
    {
        $hex = bin2hex($binary);

        return substr($hex, 0, 8) . '-' . substr($hex, 8, 4) . '-' . substr($hex, 12, 4) . '-' . substr($hex, 16, 4) . '-' . substr($hex, 20);
    }
}
