<?php

namespace App\Enum;

/**
 * TCG games and their shorthand identifiers
 */
enum Game: string
{
    case MagicTheGathering = 'mtg';
    case Pokemon = 'pkm';
    case Lorcana = 'lor';
    case DraganBallSuper = 'dbs';
    case OnePiece = 'op';
}
