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
}
