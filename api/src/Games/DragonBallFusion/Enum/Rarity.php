<?php declare(strict_types=1);

namespace App\Games\DragonBallFusion\Enum;

enum Rarity: string
{
    case Leader = 'L';
    case Common = 'C';
    case Uncommon = 'UC';
    case Rare = 'R';
    case SuperRare = 'SR';
    case SecretRare = 'SCR';
    case Promo = 'PR';

//    case SpecialRare = 'SPR';
//    case AlternateArt = 'AA';
//    case RebootLeader = 'RL';
//    case Foil = 'F';
//    case DragonBallRare = 'DBR';
//    case GodRare = 'GDR';
}
