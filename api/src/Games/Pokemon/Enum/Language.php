<?php declare(strict_types=1);

namespace App\Games\Pokemon\Enum;

/**
 * TCGdex serves each card per-locale. For the Western/international family (en, fr, de, ...)
 * that's a true translation sharing one `id`/set scheme — but Japanese (and likely Korean/
 * Chinese) is a structurally different release line with its own set splits and no
 * cross-reference to the international `id` at all. There's no reliable way to relate an EN
 * card/set to its JA "equivalent" via TCGdex's data, so this app treats each language as an
 * independent, unlinked catalog — see {@see \App\Games\Pokemon\Entity\Card::$tcgdexId}.
 *
 * Covers every locale TCGdex supports; which of these are actually imported is a separate,
 * app-level concern (see SUPPORTED_LANGUAGES in .env), mirroring how MTG's own Language enum
 * lists every Scryfall language while ScryfallService filters at import time.
 */
enum Language: string
{
    case English = 'en';
    case French = 'fr';
    case Spanish = 'es';
    case SpanishMexico = 'es-mx';
    case Italian = 'it';
    case Portuguese = 'pt';
    case PortugueseBrazil = 'pt-br';
    case PortuguesePortugal = 'pt-pt';
    case German = 'de';
    case Dutch = 'nl';
    case Polish = 'pl';
    case Russian = 'ru';
    case Japanese = 'ja';
    case Korean = 'ko';
    case ChineseTraditional = 'zh-tw';
    case Indonesian = 'id';
    case Thai = 'th';
    case ChineseSimplified = 'zh-cn';
}
