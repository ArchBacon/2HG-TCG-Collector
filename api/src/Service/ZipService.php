<?php declare(strict_types=1);

namespace App\Service;

use UnexpectedValueException;
use ZipArchive;

/**
 * Small service class for extracting zip and gzip archives to a sibling path (the archive's own
 * path with its extension stripped).
 */
final readonly class ZipService
{
    /**
     * @see https://stackoverflow.com/a/3293251
     */
    public function unpack(string $filePath): string
    {
        if (str_contains($filePath, '.zip')) {
            return $this->unpackZip($filePath);
        }

        if (str_contains($filePath, '.gz')) {
            return $this->unpackGZip($filePath);
        }

        throw new UnexpectedValueException(sprintf('Unsupported archive type: "%s".', $filePath));
    }

    private function unpackZip(string $filePath): string
    {
        $zip = new ZipArchive();

        if ($zip->open($filePath) !== true) {
            throw new \RuntimeException(sprintf('Could not open zip file "%s"', $filePath));
        }
        $extractPath = str_replace('.zip', '', $filePath);
        if (!mkdir($extractPath, 0755, true) && !is_dir($extractPath)) {
            throw new \RuntimeException(sprintf('Directory "%s" was not created', $extractPath));
        }

        $zip->extractTo($extractPath);
        $zip->close();
        unlink($filePath);

        return $extractPath;
    }

    private function unpackGZip(string $filePath): string
    {
        $bufferSize = 1048576; // Read 1MiB at a time
        $outputPath = str_replace('.gz', '', $filePath);

        // Open files
        $file = gzopen($filePath, 'rb');
        if ($file === false) {
            throw new UnexpectedValueException(sprintf('Could not open gzip file "%s".', $filePath));
        }

        $output = fopen($outputPath, 'wb');
        if ($output === false) {
            gzclose($file);
            throw new UnexpectedValueException(sprintf('Could not open output file "%s".', $outputPath));
        }

        // Write unpacked file
        while (!gzeof($file)) {
            $chunk = gzread($file, $bufferSize);
            if ($chunk === false) {
                fclose($output);
                gzclose($file);
                throw new UnexpectedValueException(sprintf('Could not read gzip file "%s".', $filePath));
            }
            fwrite($output, $chunk);
        }

        fclose($output);
        gzclose($file);
        unlink($filePath);

        return $outputPath;
    }
}
