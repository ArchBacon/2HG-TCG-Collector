<?php

namespace App\Enum;

/**
 * TCG games and their shorthand identifiers
 */
enum Game: string
{
    case MagicTheGathering = 'mtg';
    case Pokemon = 'pokemon';
    case Lorcana = 'lorcana';
    case DragonBallFusion = 'dragonballfusion';
    case OnePiece = 'onepiece';

    /**
     * @return class-string<\App\ApiResource\Set>
     */
    public function setClass(): string
    {
        return match ($this) {
            self::MagicTheGathering => \App\Games\MTG\Entity\Set::class,
            self::Pokemon => \App\Games\Pokemon\Entity\Set::class,
            self::Lorcana => \App\Games\Lorcana\Entity\Set::class,
            self::DragonBallFusion => \App\Games\DragonBallFusion\Entity\Set::class,
            self::OnePiece => \App\Games\OnePiece\Entity\Set::class,
        };
    }

    /**
     * @return class-string<\App\ApiResource\Card>
     */
    public function cardClass(): string
    {
        return match ($this) {
            self::MagicTheGathering => \App\Games\MTG\Entity\Card::class,
            self::Pokemon => \App\Games\Pokemon\Entity\Card::class,
            self::Lorcana => \App\Games\Lorcana\Entity\Card::class,
            self::DragonBallFusion => \App\Games\DragonBallFusion\Entity\Card::class,
            self::OnePiece => \App\Games\OnePiece\Entity\Card::class,
        };
    }
}
