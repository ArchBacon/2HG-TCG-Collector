<?php declare(strict_types=1);

namespace App\Games\Pokemon\Enum;

enum Category: string
{
    case Pokemon = 'Pokemon';
    case Trainer = 'Trainer';
    case Energy = 'Energy';
}
