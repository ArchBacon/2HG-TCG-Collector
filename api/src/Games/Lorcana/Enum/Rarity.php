<?php declare(strict_types=1);

namespace App\Games\Lorcana\Enum;

enum Rarity: string
{
    case Common = 'Common';
    case Uncommon = 'Uncommon';
    case Rare = 'Rare';
    case SuperRare = 'Super Rare';
    case Epic = 'Epic';
    case Legendary = 'Legendary';
    case Enchanted = 'Enchanted';
    case Iconic = 'Iconic';
}
