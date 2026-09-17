<?php declare(strict_types=1);

namespace App\Contract;

use App\Enum\IconImportType;
use App\Enum\ImageImportType;

/**
 * One implementation per game (e.g. MTG's {@see \App\Games\MTG\Service\ScryfallImportServiceV1}),
 * defining the standard set of import operations every game package must provide: sets,
 * symbology, set icons, card data, and card images.
 *
 * Unlike {@see \App\Service\ImageJobHandler}, there's no tagged locator resolving implementations
 * by game yet — each game's own console commands (e.g.
 * {@see \App\Games\MTG\Command\ImportScryfallCardsCommand}) depend on their concrete service
 * directly rather than on this interface. This contract exists to keep that shape consistent
 * across games, and is the seam a future cross-game dispatcher would resolve against.
 */

interface ImportServiceInterfaceV1
{
    /**
     * Imports all card data into the database
     *
     * @param ImageImportType $importType configuration on what images to import
     * @param (callable(int $importedSoFar, float $fractionComplete): void)|null $onProgress
     *        called after each batch is committed; $fractionComplete is 0.0-1.0
     * @return int Amount of cards imported
     */
    public function syncCardInfo(ImageImportType $importType, ?callable $onProgress = null): int;

    /**
     * Imports all set data into the database
     *
     * @param (callable(int $syncedSoFar, float $fractionComplete): void)|null $onProgress
     *        called after each set is persisted; $fractionComplete is 0.0-1.0
     * @return int Amount of sets imported
     */
    public function syncSetInfo(?callable $onProgress = null): int;

    /**
     * Imports all set icons. Does not require image jobs.
     *
     * @param (callable(int $processedSoFar, float $fractionComplete): void)|null $onProgress
     *        called after each set icon is checked/downloaded; $fractionComplete is 0.0-1.0
     * @return int Amount of set icons processed (checked or downloaded) — not just newly
     *         downloaded ones, matching {@see self::syncCardInfo()}/{@see self::syncSetInfo()}'s
     *         processed-count convention.
     */
    public function syncSetIcons(IconImportType $importType, ?callable $onProgress = null): int;
}
