<?php declare(strict_types=1);

namespace App\Service;

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
        $output = fopen($outputPath, 'wb');

        // Write unpacked file
        while (!gzeof($file)) {
            fwrite($output, gzread($file, $bufferSize));
        }

        fclose($output);
        gzclose($file);
        unlink($filePath);

        return $outputPath;
    }
}
