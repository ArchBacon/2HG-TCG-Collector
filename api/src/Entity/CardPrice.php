<?php declare(strict_types=1);

namespace App\Entity;

use DateTimeImmutable;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Uid\Uuid;

/**
 * A card's market price at one source, for one finish, as the card data gave it at the last sync:
 * e.g. Cardmarket's trend in EUR for the foil, or TCGplayer's market price in USD. Kept in the
 * source's own currency; nothing is converted.
 *
 * Written by the importers through {@see \App\Service\CardPriceStore}, not through the ORM. Like
 * {@see CardListing}, not FK-linked to any game's card table: {@see self::$cardId} is a loose
 * reference, resolved per {@see self::$game}; `finish` is the game's own word for it (MTG:
 * nonfoil/foil/etched; Pokémon: normal/holo/reverse/firstEdition; the others: normal).
 */
#[ORM\Entity]
#[ORM\Table(name: 'card_price')]
#[ORM\UniqueConstraint(name: 'uniq_card_price_card_source_finish', columns: ['card_id', 'source', 'finish'])]
class CardPrice
{
    #[ORM\Id]
    #[ORM\Column(type: 'bigint', unique: true)]
    #[ORM\GeneratedValue(strategy: 'AUTO')]
    public private(set) int $id;

    #[ORM\Column(type: 'string', length: 20)]
    public private(set) string $game;

    #[ORM\Column(type: 'uuid')]
    public private(set) Uuid $cardId;

    /** Where the price is from: `cardmarket` or `tcgplayer`. */
    #[ORM\Column(type: 'string', length: 20)]
    public private(set) string $source;

    #[ORM\Column(type: 'string', length: 20)]
    public private(set) string $finish;

    /** ISO 4217, e.g. `EUR`. */
    #[ORM\Column(type: 'string', length: 3)]
    public private(set) string $currency;

    #[ORM\Column(type: 'decimal', precision: 10, scale: 2)]
    public private(set) string $price;

    /** When the source last updated it, as far as the card data says; else when it was synced. */
    #[ORM\Column(type: 'datetime_immutable')]
    public private(set) DateTimeImmutable $updatedAt;

    /** When a sync last wrote it: one that doesn't, for a card it imports, removes it. */
    #[ORM\Column(type: 'datetime_immutable')]
    public private(set) DateTimeImmutable $syncedAt;

    private function __construct() {}
}
