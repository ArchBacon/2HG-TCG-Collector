<?php declare(strict_types=1);

namespace App\Service;

use App\Enum\Game;
use Symfony\Component\Uid\Uuid;

/**
 * What {@see ProductMatcher} made of a shop product: the card and finish it's for, or why it
 * couldn't tell (with the game, when at least the set was found).
 */
final readonly class ProductMatch
{
    private function __construct(
        public ?Game $game,
        public ?Uuid $cardId,
        public ?string $finish,
        public ?string $reason,
    ) {}

    public static function found(Game $game, Uuid $cardId, string $finish): self
    {
        return new self($game, $cardId, $finish, null);
    }

    public static function missed(?Game $game, string $reason): self
    {
        return new self($game, null, null, $reason);
    }
}
