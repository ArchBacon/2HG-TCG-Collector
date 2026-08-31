<?php declare(strict_types=1);

namespace App\Enum;

/**
 * How game card images should be imported
 */
enum ImageImportType
{
    case SkipAll;   // skip all image imports
    case NewOnly;   // import missing images only
    case All;       // (re)import all images
}
