<?php declare(strict_types=1);

namespace App\Service;

use function min;

final class ProgressReporter
{
    private int $total;
    private int $progress = 0;

    public function __construct(int $total = 0)
    {
        $this->total = $total;
    }

    public function advance(int $amount = 1): void
    {
        $this->progress += $amount;
        if ($this->total > 0) {
            $this->progress = min($this->progress, $this->total);
        }
    }

    /**
     * @param (callable(int $progress, float $fractionComplete): void)|null $onProgress
     * @return int Number of items processed so far
     */
    public function report(?callable $onProgress = null): int
    {
        if ($onProgress !== null) {
            $fraction = $this->total > 0 ? $this->progress / $this->total : 0.0;
            $onProgress($this->progress, $fraction);
        }

        return $this->progress;
    }
}
