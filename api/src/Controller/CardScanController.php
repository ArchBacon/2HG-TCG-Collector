<?php declare(strict_types=1);

namespace App\Controller;

use App\Enum\Game;
use App\Service\MagicSorterClient;
use Symfony\Component\HttpFoundation\File\UploadedFile;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\IsGranted;
use Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface;
use function file_get_contents;
use function json_decode;
use function json_last_error;

/**
 * Card scanning for the app: forwards a camera image to Magic Sorter and returns its JSON
 * response unchanged, with Magic Sorter's status code.
 *
 * POST /api/scan/{game}, multipart with an `image` file field. Optional query/form fields:
 * `condition` (default NM), `lang` (default en), `foil` (default false).
 *
 * Errors that never reached Magic Sorter (bad upload, not configured, unreachable) are
 * `{"error": "..."}` like the rest of the API.
 */
#[Route('/api/scan')]
final class CardScanController
{
    private const int MAX_UPLOAD_BYTES = 10 * 1024 * 1024;

    public function __construct(private readonly MagicSorterClient $magicSorter) {}

    #[Route('/{game}', methods: ['POST'])]
    // Users only, so the server's Magic Sorter credentials aren't an open proxy.
    #[IsGranted('ROLE_USER')]
    public function scan(Game $game, Request $request): JsonResponse
    {
        if (!$this->magicSorter->isConfigured()) {
            return new JsonResponse(['error' => 'Card scanning is not configured.'], Response::HTTP_SERVICE_UNAVAILABLE);
        }

        $file = $request->files->get('image');
        if (!$file instanceof UploadedFile || !$file->isValid()) {
            return new JsonResponse(['error' => 'Missing or invalid "image" file.'], Response::HTTP_BAD_REQUEST);
        }
        if ($file->getSize() > self::MAX_UPLOAD_BYTES) {
            return new JsonResponse(['error' => 'Image is larger than 10 MB.'], Response::HTTP_REQUEST_ENTITY_TOO_LARGE);
        }

        try {
            ['status' => $status, 'body' => $body] = $this->magicSorter->identify(
                gameMode: $game->value,
                imageData: (string) file_get_contents($file->getPathname()),
                condition: $this->param($request, 'condition', 'NM'),
                language: $this->param($request, 'lang', 'en'),
                foil: $this->param($request, 'foil', 'false') === 'true',
            );
        } catch (TransportExceptionInterface) {
            return new JsonResponse(['error' => 'Card scanner could not be reached.'], Response::HTTP_GATEWAY_TIMEOUT);
        }

        json_decode($body);
        if (json_last_error() !== JSON_ERROR_NONE) {
            return new JsonResponse(['error' => 'Card scanner returned an unreadable response.', 'status' => $status], Response::HTTP_BAD_GATEWAY);
        }

        return JsonResponse::fromJsonString($body, $status);
    }

    /** A field from the query string or the multipart form, whichever the app used. */
    private function param(Request $request, string $name, string $default): string
    {
        $value = $request->query->getString($name, $request->request->getString($name));

        return $value !== '' ? $value : $default;
    }
}
