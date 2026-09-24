<?php declare(strict_types=1);

namespace App\Service;

use App\Enum\Game;
use GdImage;
use RuntimeException;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use function array_keys;
use function sprintf;

final readonly class CardImageService
{
    private const int WEBP_QUALITY = 80;
    private const array SIZES = [
        'small' => [146, 204],
        'medium' => [488, 680],
        'large' => [745, 1040],
    ];

    public function __construct(
        #[Autowire('%public_dir%')]
        private string $publicDir,
    ) {}

    public function hasAllSizes(Game $game, string $id): bool
    {
        return array_all(
            [...array_keys(self::SIZES)],
            fn($size) => is_file($this->path($game, $size, $id))
        );
    }

    public function convertAndSave(string $imageData, Game $game, string $id): void
    {
        $source = imagecreatefromstring($imageData);
        if (!$source) {
            throw new RuntimeException(sprintf('Could not decode image data for "%s" (%s).', $id, $game->value));
        }

        foreach (self::SIZES as $size => [$maxWidth, $maxHeight]) {
            $resized = $this->resize($source, $maxWidth, $maxHeight);
            $this->save($resized, $this->path($game, $size, $id));
            imagedestroy($resized);
        }
        imagedestroy($source);
    }

    private function path(Game $game, string $size, string $id): string
    {
        return "$this->publicDir\\$game->value\\$size\\$id.webp";
    }

    private function resize(GdImage $source, int $maxWidth, int $maxHeight): GdImage
    {
        $sourceWidth = imagesx($source);
        $sourceHeight = imagesy($source);
        $scale = min($maxWidth / $sourceWidth, $maxHeight / $sourceHeight);
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
