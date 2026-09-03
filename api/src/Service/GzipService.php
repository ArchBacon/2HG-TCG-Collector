<?php declare(strict_types=1);

namespace App\Service;

use UnexpectedValueException;

/**
 * Small service class for extracting Gzip files.
 */
final class GzipService
{
    /**
     * @see https://stackoverflow.com/a/3293251
     */
    public static function unpack(string $filePath): string
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
