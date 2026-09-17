<?php declare(strict_types=1);

namespace App\Contract;

use App\Enum\IconImportType;
use App\Enum\ImageImportType;

interface ImportServiceInterface
{
    /**
     * Imports all set data and icons
     *
     * @param (callable(int $syncedSoFar, float $fractionComplete): void)|null $onProgress
     *        called after each set is persisted; $fractionComplete is 0.0-1.0
     */
    public function importSets(IconImportType $importType, ?callable $onProgress = null): void;

    /**
     * Imports all card data and queues image downloads
     *
     * @param ImageImportType $importType configuration on what images to import
     * @param (callable(int $importedSoFar, float $fractionComplete): void)|null $onProgress
     *        called after each batch is committed; $fractionComplete is 0.0-1.0
     */
    public function importCards(ImageImportType $importType, ?callable $onProgress = null): void;


}
