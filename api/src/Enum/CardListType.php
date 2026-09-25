<?php declare(strict_types=1);

namespace App\Enum;

enum CardListType: string
{
    case Collection = 'collection';
    case Wishlist = 'wishlist';
}
