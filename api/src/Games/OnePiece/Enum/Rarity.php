<?php declare(strict_types=1);

namespace App\Games\OnePiece\Enum;

enum Rarity: string
{
    case Common = 'C';
    case Uncommon = 'UC';
    case Rare = 'R';
    case Leader = 'L';
    case SuperRare = 'SR';
    case SecretRare = 'SEC';
    case Promo = 'PR';
    case TreasureRare = 'TR';
}
