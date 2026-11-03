<?php declare(strict_types=1);

namespace App\Service;

use App\ApiResource\Card;
use App\Enum\Game;
use Doctrine\ORM\EntityManagerInterface;
use function addcslashes;
use function ctype_digit;
use function explode;
use function implode;
use function in_array;
use function is_array;
use function is_int;
use function is_string;
use function json_decode;
use function ltrim;
use function mb_strtolower;
use function preg_match_all;
use function preg_replace;
use function str_starts_with;
use function strrpos;
use function substr;
use function Symfony\Component\String\u;
use function trim;

/**
 * Finds our card for what Magic Sorter recognized in a scan (its `result`).
 *
 * Magic: by Magic Sorter's `ext_id`, which is the Scryfall id. The other games don't share an id
 * with ours, so by name and number, preferring the same set and language:
 * - Pokémon: its sets are pokemontcg.io's (`SV3PT5`), ours TCGdex's (`sv03.5`): compared as
 *   their letter and number groups, `pt5` as `.5`.
 * - One Piece: `OP01` #77 is our `OP-01` `OP01-077`, which variants (box topper, alternate art)
 *   share: the one named just like the scan wins.
 * - Lorcana: its sets are numbers (`13`), ours codes (`aov`), so name and number only, which a
 *   card's subtitle makes unique enough.
 */
final readonly class ScannedCardMatcher
{
    /** Cards to look through, by the first word of the name; far more than one name ever has. */
    private const int MAX_CANDIDATES = 500;

    public function __construct(private EntityManagerInterface $entityManager) {}

    /**
     * What Magic Sorter saw in a scan, for the app and the logs.
     *
     * @param array<mixed> $result Magic Sorter's `result`
     *
     * @return array{title: string, set: string, number: string, lang: string, extId: string}
     */
    public static function recognized(array $result): array
    {
        return [
            'title' => self::string($result['title'] ?? null),
            'set' => self::string($result['set'] ?? null),
            'number' => self::string($result['num'] ?? null),
            'lang' => self::string($result['lang'] ?? null),
            'extId' => self::string($result['ext_id'] ?? null),
        ];
    }

    /**
     * @param array<mixed> $result Magic Sorter's `result`
     */
    public function match(Game $game, array $result): ?Card
    {
        $extId = self::string($result['ext_id'] ?? null);
        if ($game === Game::MagicTheGathering && $extId !== '') {
            /** @var ?Card $card */
            $card = $this->entityManager->createQueryBuilder()
                ->select('c', 's')
                ->from($game->cardClass(), 'c')
                ->join('c.set', 's')
                ->where('c.details.scryfallId = :id')
                ->setParameter('id', $extId)
                ->setMaxResults(1)
                ->getQuery()
                ->getOneOrNullResult();
            if ($card !== null) {
                return $card;
            }
        }

        return $this->matchByName($game, $result);
    }

    /**
     * @param array<mixed> $result
     */
    private function matchByName(Game $game, array $result): ?Card
    {
        $title = self::string($result['title'] ?? null);
        $number = self::number(self::string($result['num'] ?? null));
        if ($title === '' || $number === '') {
            return null;
        }
        // Also the name the game itself uses, when it has one (`Woody - Helping a Friend`)
        $names = [self::name($title)];
        $tcgName = self::string(self::extra($result)['tcg_name'] ?? null);
        if ($tcgName !== '') {
            $names[] = self::name($tcgName);
        }
        $set = self::setKey(self::string($result['set'] ?? null));
        $lang = self::string($result['lang'] ?? null);

        $firstWord = explode(' ', trim($title))[0];
        /** @var list<Card> $candidates */
        $candidates = $this->entityManager->createQueryBuilder()
            ->select('c', 's')
            ->from($game->cardClass(), 'c')
            ->join('c.set', 's')
            ->where('c.name LIKE :prefix')
            ->setParameter('prefix', addcslashes($firstWord, '%_') . '%')
            ->setMaxResults(self::MAX_CANDIDATES)
            ->getQuery()
            ->getResult();

        $best = null;
        $bestScore = 0;
        foreach ($candidates as $card) {
            if (self::number($card->number) !== $number) {
                continue;
            }
            $name = self::name($card->name);
            $exact = in_array($name, $names, true);
            if (!$exact && !self::startsLike($name, $names)) {
                continue;
            }

            $score = 1
                + ($exact ? 4 : 0)
                + ($set !== '' && self::setKey($card->set->code) === $set ? 2 : 0)
                + ($card->lang->value === $lang ? 1 : 0);
            if ($score > $bestScore) {
                $bestScore = $score;
                $best = $card;
            }
        }

        return $best;
    }

    /**
     * Magic Sorter's `extra`, which it sends as a JSON string.
     *
     * @param array<mixed> $result
     *
     * @return array<mixed>
     */
    private static function extra(array $result): array
    {
        $extra = $result['extra'] ?? null;
        if (is_string($extra)) {
            try {
                $extra = json_decode($extra, true, 16, JSON_THROW_ON_ERROR);
            } catch (\JsonException) {
                return [];
            }
        }

        return is_array($extra) ? $extra : [];
    }

    private static function string(mixed $value): string
    {
        return is_string($value) || is_int($value) ? trim((string) $value) : '';
    }

    /**
     * A card number to compare: the part after a set prefix (`OP01-077` is `077`), lower case,
     * without leading zeros (`077` is `77`).
     */
    private static function number(string $number): string
    {
        $number = mb_strtolower(trim($number));
        $dash = strrpos($number, '-');
        if ($dash !== false) {
            $number = substr($number, $dash + 1);
        }
        $trimmed = ltrim($number, '0');

        return $trimmed !== '' ? $trimmed : ($number !== '' ? '0' : '');
    }

    /**
     * A name to compare: only its letters and digits, without accents, lower case.
     */
    private static function name(string $name): string
    {
        return (string) preg_replace('/[^a-z0-9]/', '', u($name)->ascii()->lower()->toString());
    }

    /**
     * Whether $name and one of $names start alike (`Perona (Box Topper)` and `Perona`).
     *
     * @param list<string> $names
     */
    private static function startsLike(string $name, array $names): bool
    {
        foreach ($names as $other) {
            if ($name !== '' && $other !== '' && (str_starts_with($name, $other) || str_starts_with($other, $name))) {
                return true;
            }
        }

        return false;
    }

    /**
     * A set code to compare: its letter and number groups, numbers without leading zeros, and
     * pokemontcg.io's `pt` as a point (`SV3PT5` and `sv03.5` are both `sv-3-5`, `OP01` and `OP-01`
     * both `op-1`).
     */
    private static function setKey(string $code): string
    {
        $code = (string) preg_replace('/(\d)pt(\d)/', '$1.$2', mb_strtolower($code));
        if (!preg_match_all('/[a-z]+|\d+/', $code, $groups)) {
            return '';
        }
        $parts = [];
        foreach ($groups[0] as $group) {
            $parts[] = ctype_digit($group) ? (ltrim($group, '0') ?: '0') : $group;
        }

        return implode('-', $parts);
    }
}
