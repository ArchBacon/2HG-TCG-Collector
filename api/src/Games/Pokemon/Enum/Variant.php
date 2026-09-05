<?php declare(strict_types=1);

namespace App\Games\Pokemon\Enum;

enum Variant: string
{
    case FirstEdition = 'firstEdition';
    case Holo = 'holo';
    case Normal = 'normal';
    case Reverse = 'reverse';
    case Promo = 'wPromo';
}
