<?php declare(strict_types=1);

namespace App\Service;

use GdImage;
use RuntimeException;
use function sprintf;

final readonly class ImageService
{
    private const int WEBP_QUALITY = 80;

    public function convertAndSave(string $imageData, string $path, ?int $newHeight = null): void
    {
        /** @var GdImage|false $source */
        $source = imagecreatefromstring($imageData);
        if (!$source) {
            throw new RuntimeException(sprintf('Could not decode image data for "%s".', $path));
        }

        $height = $newHeight ?? imagesy($source);
        $resized = $this->resize($source, $height);
        $this->save($resized, $path . '.webp');
        imagedestroy($resized);

        imagedestroy($source);
    }

    private function resize(GdImage $source, int $maxHeight): GdImage
    {
        $sourceWidth = imagesx($source);
        $sourceHeight = imagesy($source);
        $scale = min($maxHeight / $sourceHeight, 1.0);
        $width = max(1, (int) round($sourceWidth * $scale));
        $height = max(1, (int) round($sourceHeight * $scale));

        $target = imagecreatetruecolor($width, $height);
        imagealphablending($target, false);
        imagesavealpha($target, true);
        imagecopyresampled($target, $source, 0, 0, 0, 0, $width, $height, $sourceWidth, $sourceHeight);

        return $target;
    }

    private function save(GdImage $image, string $path): void
    {
        if (!imagewebp($image, $path, self::WEBP_QUALITY)) {
            throw new RuntimeException(sprintf('Failed to write WebP file "%s".', $path));
        }
    }
}
