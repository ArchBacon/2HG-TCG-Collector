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

    public function count(): int
    {
        return $this->progress;
    }

    /**
     * @param (callable(int $progress, float $fractionComplete): void)|null $onProgress
     * @param (callable(): float)|null $fraction Overrides the default progress/total fraction —
     *        for callers tracking completion against something other than this reporter's own
     *        $total (e.g. bytes read instead of items processed), where progress/total wouldn't
     *        mean anything.
     * @return int Number of items processed so far
     */
    public function report(?callable $onProgress = null, ?callable $fraction = null): int
    {
        if ($onProgress !== null) {
            $internalFraction = $this->total > 0 ? $this->progress / $this->total : 0.0;
            $fractionComplete = $fraction !== null ? $fraction() : $internalFraction;
            $onProgress($this->progress, $fractionComplete);
        }

        return $this->progress;
    }
}
