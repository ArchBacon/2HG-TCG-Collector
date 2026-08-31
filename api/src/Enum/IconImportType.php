<?php declare(strict_types=1);

namespace App\Enum;

/**
 * How game icons should be imported
 */
enum IconImportType
{
    case NewOnly;   // import missing icons only
    case All;       // (re)import all icons
}
