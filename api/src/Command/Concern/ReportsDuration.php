<?php declare(strict_types=1);

namespace App\Command\Concern;

use Symfony\Component\Console\Style\SymfonyStyle;

/**
 * Wraps a command's execute() so every run reports how long it took, success or failure.
 */
trait ReportsDuration
{
    private float $durationStart;

    private function startDuration(): void
    {
        $this->durationStart = microtime(true);
    }

    private function reportDuration(SymfonyStyle $io): void
    {
        $io->comment(\sprintf('Finished in %s.', $this->formatDuration(microtime(true) - $this->durationStart)));
    }

    private function formatDuration(float $seconds): string
    {
        if ($seconds < 60.0) {
            return \sprintf('%.1fs', $seconds);
        }

        $minutes = (int) ($seconds / 60);
        $remainingSeconds = $seconds - $minutes * 60;

        return \sprintf('%dm %.1fs', $minutes, $remainingSeconds);
    }
}
