<?php

namespace App\Games\MTG\Enum;

enum Rarity: string
{
    case Common = 'common';
    case Uncommon = 'uncommon';
    case Rare = 'rare';
    case Special = 'special';
    case Mythic = 'mythic';
    case Bonus = 'bonus';
}
