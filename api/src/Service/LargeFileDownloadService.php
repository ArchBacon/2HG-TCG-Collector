<?php declare(strict_types=1);

namespace App\Service;

use Symfony\Component\Process\Process;

/**
 * Symfony's Http stream keeps running out of memory on large files.
 * This service downloads those files using curl.
 */
final readonly class LargeFileDownloadService
{
    public function __construct(
        private string $storageDir,
    ) {}

    public function download(string $downloadLink, string $filename): string
    {
        $outputPath = $this->storageDir . DIRECTORY_SEPARATOR . $filename;
        $process = new Process([
            'curl',
            '-f',
            '-o', $outputPath,
            $downloadLink
        ]);
        $process->setTimeout(600);
        $process->run();

        if (!$process->isSuccessful()) {
            throw new \RuntimeException('curl failed: ' . $process->getErrorOutput());
        }

        return $outputPath;
    }
}
