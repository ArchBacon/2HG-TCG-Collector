<?php declare(strict_types=1);

namespace App\Service;

use App\ApiResource\Card;
use App\ApiResource\Set;
use App\Entity\CardListingCondition;
use App\Enum\Game;
use App\Games\MTG\Entity\Card as MtgCard;
use App\Games\Pokemon\Entity\Card as PokemonCard;
use DateTimeImmutable;
use Doctrine\DBAL\ArrayParameterType;
use Doctrine\ORM\EntityManagerInterface;
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
     * Just what's needed to filter and sort every card of $game, without loading the cards
     * themselves: in set order (newest set first) and number order.
     *
     * @return list<array{id: Uuid, name: string, number: string, rarity: ?string, artist: ?string, setCode: string, setName: string}>
     */
    public function findCatalogRows(Game $game): array
    {
        /** @var list<array{id: Uuid, name: string, number: string, rarity: ?string, artist: ?string, setCode: string, setName: string, releasedAt: ?\DateTimeInterface}> $rows */
        $rows = $this->entityManager->createQueryBuilder()
            ->select('c.id AS id', 'c.name AS name', 'c.number AS number', 'c.rarity AS rarity', 'c.artist AS artist', 's.code AS setCode', 's.name AS setName', 's.releasedAt AS releasedAt')
            ->from($game->cardClass(), 'c')
            ->join('c.set', 's')
            ->getQuery()
            ->getArrayResult();

        usort($rows, static fn (array $a, array $b): int
            => [$b['releasedAt'], $a['setCode']] <=> [$a['releasedAt'], $b['setCode']]
            ?: strnatcmp($a['number'], $b['number']));

        return array_map(static function (array $row): array {
            unset($row['releasedAt']);

            return $row;
        }, $rows);
    }

    /**
     * The sets of $game, newest first, and the rarities and artists (A to Z) its cards have, to
     * filter the catalog on.
     *
     * @return array{sets: list<array{code: string, name: string}>, rarities: list<string>, artists: list<string>}
     */
    public function findCatalogFilters(Game $game): array
    {
        /** @var list<array{code: string, name: string}> $sets */
        $sets = $this->entityManager->createQueryBuilder()
            ->select('s.code AS code', 's.name AS name')
            ->from($game->setClass(), 's')
            ->orderBy('s.releasedAt', 'DESC')
            ->addOrderBy('s.code', 'ASC')
            ->getQuery()
            ->getArrayResult();

        /** @var list<string> $rarities */
        $rarities = $this->entityManager->createQueryBuilder()
            ->select('DISTINCT c.rarity')
            ->from($game->cardClass(), 'c')
            ->where('c.rarity IS NOT NULL')
            ->andWhere("c.rarity <> ''")
            ->orderBy('c.rarity', 'ASC')
            ->getQuery()
            ->getSingleColumnResult();

        /** @var list<string> $artists */
        $artists = $this->entityManager->createQueryBuilder()
            ->select('DISTINCT c.artist')
            ->from($game->cardClass(), 'c')
            ->where('c.artist IS NOT NULL')
            ->andWhere("c.artist <> ''")
            ->orderBy('c.artist', 'ASC')
            ->getQuery()
            ->getSingleColumnResult();

        return ['sets' => $sets, 'rarities' => $rarities, 'artists' => $artists];
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
