<?php declare(strict_types=1);

namespace App\Service;

use App\ApiResource\Set;
use App\Enum\Game;
use App\Enum\Language;
use Doctrine\DBAL\ArrayParameterType;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\Uid\Uuid;
use Symfony\Contracts\Service\ResetInterface;
use function array_filter;
use function array_map;
use function array_slice;
use function array_values;
use function count;
use function ctype_digit;
use function explode;
use function implode;
use function in_array;
use function ltrim;
use function mb_strtolower;
use function preg_replace;
use function sprintf;
use function str_starts_with;
use function Symfony\Component\String\u;
use function trim;

/**
 * Finds the card a shop product is for. 2HG names its products `<SET> <number> - <name>`, with
 * the finish as an optional last part (`EVS 004 - Jumpluff - Reverse Holo`), and gives the set by
 * name (`reference`). So: the set by name, in whichever game has it, then the card by number in
 * that set, checked against the name, and the finish from the suffix.
 *
 * Only confident matches: anything off (no set, no card, another name, several cards) is a miss,
 * with the reason, for the admin to link by hand.
 *
 * Keeps the sets and cards it looked up until the request ends ({@see self::reset()}).
 */
final class ProductMatcher implements ResetInterface
{
    /**
     * Product name suffix (lower case) => finish, per game; '' is no suffix.
     *
     * @var array<string, array<string, string>>
     */
    private const array FINISHES = [
        'pokemon' => ['' => 'normal', 'holo' => 'holo', 'reverse holo' => 'reverse', 'reverse' => 'reverse'],
        'mtg' => ['' => 'nonfoil', 'foil' => 'foil', 'etched' => 'etched', 'etched foil' => 'etched'],
    ];

    /**
     * Without a suffix, the first of these the card comes in; e.g. a holo rare only comes in holo
     * (and reverse), so its product without a suffix is the holo.
     *
     * @var array<string, list<string>>
     */
    private const array PLAIN_FINISHES = [
        'pokemon' => ['normal', 'holo'],
        'mtg' => ['nonfoil', 'foil'],
    ];

    /** @var array<string, list<array{game: Game, sets: list<Set>}>> by set name and language */
    private array $sets = [];

    /** @var array<string, list<array{id: Uuid, number: string, name: string, finishes: list<string>}>> by game, set name and language */
    private array $cards = [];

    public function __construct(private readonly EntityManagerInterface $entityManager) {}

    public function reset(): void
    {
        $this->sets = [];
        $this->cards = [];
    }

    public function match(string $name, string $setName, ?Language $lang): ProductMatch
    {
        $inGames = $this->findSets($setName, $lang);
        if ($inGames === []) {
            return ProductMatch::missed(null, sprintf('No set named "%s".', $setName));
        }
        if (count($inGames) > 1) {
            return ProductMatch::missed(null, sprintf('There\'s a set named "%s" in several games.', $setName));
        }
        $game = $inGames[0]['game'];

        // `EVS 004 - Jumpluff - Reverse Holo` => EVS 004, Jumpluff, Reverse Holo
        $parts = array_values(array_filter(explode(' - ', (string) preg_replace('/\s+/', ' ', trim($name))), static fn (string $part): bool => trim($part) !== ''));
        $head = explode(' ', trim($parts[0] ?? '')); // Whitespace is single spaces by now
        if (count($parts) < 2 || count($head) < 2) {
            return ProductMatch::missed($game, 'The name isn\'t "<SET> <number> - <card name>".');
        }
        $number = $head[count($head) - 1];

        $finishes = self::FINISHES[$game->value] ?? ['' => 'normal'];
        $suffix = count($parts) > 2 ? mb_strtolower(trim($parts[count($parts) - 1])) : '';
        if ($suffix !== '' && isset($finishes[$suffix])) {
            $cardName = implode(' - ', array_slice($parts, 1, -1));
        } else {
            $suffix = '';
            $cardName = implode(' - ', array_slice($parts, 1));
        }

        $candidates = array_values(array_filter(
            $this->findCards($game, $inGames[0]['sets'], $setName, $lang),
            static fn (array $card): bool => $card['number'] === self::number($number),
        ));
        if ($candidates === []) {
            return ProductMatch::missed($game, sprintf('No card #%s in %s.', $number, $setName));
        }

        $named = array_values(array_filter($candidates, static fn (array $card): bool => self::sameName($card['name'], $cardName)));
        if ($named === []) {
            return ProductMatch::missed($game, sprintf('#%s in %s is %s, not %s.', $number, $setName, $candidates[0]['name'], $cardName));
        }
        if (count($named) > 1) {
            return ProductMatch::missed($game, sprintf('Several cards are #%s %s in %s.', $number, $cardName, $setName));
        }
        $card = $named[0];

        $finish = $finishes[$suffix] ?? 'normal';
        if ($suffix === '' && $card['finishes'] !== [] && !in_array($finish, $card['finishes'], true)) {
            foreach (self::PLAIN_FINISHES[$game->value] ?? [] as $plain) {
                if (in_array($plain, $card['finishes'], true)) {
                    $finish = $plain;
                    break;
                }
            }
        }

        return ProductMatch::found($game, $card['id'], $finish);
    }

    /**
     * The sets named $name, per game that has one.
     *
     * @return list<array{game: Game, sets: list<Set>}>
     */
    private function findSets(string $name, ?Language $lang): array
    {
        $key = mb_strtolower($name) . '|' . $lang?->value;
        if (isset($this->sets[$key])) {
            return $this->sets[$key];
        }

        $found = [];
        foreach (Game::cases() as $game) {
            $query = $this->entityManager->createQueryBuilder()
                ->select('s')
                ->from($game->setClass(), 's')
                ->where('LOWER(s.name) = :name')
                ->setParameter('name', mb_strtolower($name));
            if ($lang !== null) {
                $query->andWhere('s.lang = :lang OR s.lang IS NULL')->setParameter('lang', $lang->value);
            }

            /** @var list<Set> $sets */
            $sets = $query->getQuery()->getResult();
            if ($sets !== []) {
                $found[] = ['game' => $game, 'sets' => $sets];
            }
        }

        return $this->sets[$key] = $found;
    }

    /**
     * The cards of $sets, loaded once per set.
     *
     * @param list<Set> $sets
     *
     * @return list<array{id: Uuid, number: string, name: string, finishes: list<string>}>
     */
    private function findCards(Game $game, array $sets, string $setName, ?Language $lang): array
    {
        $key = $game->value . '|' . mb_strtolower($setName) . '|' . $lang?->value;
        if (isset($this->cards[$key])) {
            return $this->cards[$key];
        }

        $query = $this->entityManager->createQueryBuilder()
            ->select('c.id AS id', 'c.number AS number', 'c.name AS name')
            ->from($game->cardClass(), 'c')
            ->where('c.set IN (:sets)')
            ->setParameter('sets', array_map(static fn (Set $set): string => $set->id->toBinary(), $sets), ArrayParameterType::BINARY);
        if (isset(self::FINISHES[$game->value])) {
            $query->addSelect('c.details.finishes AS finishes'); // Only these games have them
        }
        if ($lang !== null) {
            $query->andWhere('c.lang = :lang')->setParameter('lang', $lang->value);
        }

        /** @var list<array{id: Uuid, number: string, name: string, finishes?: ?list<string>}> $rows */
        $rows = $query->getQuery()->getArrayResult();

        $cards = [];
        foreach ($rows as $row) {
            $cards[] = [
                'id' => $row['id'],
                'number' => self::number($row['number']),
                'name' => $row['name'],
                'finishes' => $row['finishes'] ?? [],
            ];
        }

        return $this->cards[$key] = $cards;
    }

    /**
     * A card number to compare: lower case, without leading zeros (`004` is `4`).
     */
    private static function number(string $number): string
    {
        $number = mb_strtolower(trim($number));

        if (!ctype_digit($number)) {
            return $number;
        }
        $number = ltrim($number, '0');

        return $number !== '' ? $number : '0';
    }

    /**
     * Whether the shop's name is the card's, give or take accents, punctuation and a missing part
     * at the end (`Alolan Ninetales GX` is `Alolan Ninetales-GX`).
     */
    private static function sameName(string $cardName, string $shopName): bool
    {
        $normalize = static fn (string $name): string => (string) preg_replace('/[^a-z0-9]/', '', u($name)->ascii()->lower()->toString());
        [$card, $shop] = [$normalize($cardName), $normalize($shopName)];

        return $card !== '' && $shop !== '' && (str_starts_with($card, $shop) || str_starts_with($shop, $card));
    }
}
