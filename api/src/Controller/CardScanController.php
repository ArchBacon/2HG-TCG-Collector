<?php declare(strict_types=1);

namespace App\Controller;

use App\Enum\Game;
use App\Service\MagicSorterClient;
use App\Service\ScannedCardMatcher;
use Psr\Log\LoggerInterface;
use Symfony\Component\HttpFoundation\File\UploadedFile;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\IsGranted;
use Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface;
use function file_get_contents;
use function is_array;
use function json_decode;
use function sprintf;

/**
 * Card scanning for the app: sends a camera image of a card to Magic Sorter, and finds our card
 * for what it recognized.
 *
 * POST /api/scan/{game}, multipart with an `image` file field (a JPEG of the card). Optional
 * query/form fields: `condition` (default NM), `lang` (default en), `foil` (default false).
 *
 * - 200 `{"card": {"id", "name", "number", "set": {"code", "name"}}, "recognized": {...}}`
 * - 404 `{"error", "recognized"?}`: Magic Sorter didn't recognize the card, or did (then with
 *   what it saw) but it isn't in our catalog.
 * - 422: the game can't be scanned (Magic Sorter doesn't do it).
 * - 400, 413, 502, 503, 504: a bad upload, or Magic Sorter not configured, failing or unreachable.
 *
 * `recognized` is what Magic Sorter saw: `{"title", "set", "number", "lang"}`.
 */
#[Route('/api/scan')]
final class CardScanController
{
    private const int MAX_UPLOAD_BYTES = 10 * 1024 * 1024;

    public function __construct(
        private readonly MagicSorterClient $magicSorter,
        private readonly ScannedCardMatcher $matcher,
        private readonly LoggerInterface $logger,
    ) {}

    #[Route('/{game}', methods: ['POST'])]
    // Users only, so the server's Magic Sorter credentials aren't an open proxy.
    #[IsGranted('ROLE_USER')]
    public function scan(Game $game, Request $request): JsonResponse
    {
        if ($game === Game::DragonBallFusion) {
            return new JsonResponse(['error' => 'Scanning isn\'t available for this game.'], Response::HTTP_UNPROCESSABLE_ENTITY);
        }
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

        $json = json_decode($body, true);
        if (!is_array($json)) {
            $this->logger->warning(sprintf('Magic Sorter returned an unreadable response (status %d)', $status));

            return new JsonResponse(['error' => 'Card scanner returned an unreadable response.'], Response::HTTP_BAD_GATEWAY);
        }
        if ($status === Response::HTTP_UNAUTHORIZED || $status === Response::HTTP_FORBIDDEN) {
            $this->logger->error(sprintf('Magic Sorter turned down our credentials (status %d)', $status));

            return new JsonResponse(['error' => 'Card scanning is not available.'], Response::HTTP_SERVICE_UNAVAILABLE);
        }

        // One result, or a list of them, best first; an error or nothing when it saw no card
        $result = $json['result'] ?? null;
        if (is_array($result) && array_is_list($result)) {
            $result = $result[0] ?? null;
        }
        if (!is_array($result)) {
            if ($status >= 500) {
                $this->logger->warning(sprintf('Magic Sorter failed with status %d', $status));

                return new JsonResponse(['error' => 'Card scanner failed.'], Response::HTTP_BAD_GATEWAY);
            }

            return new JsonResponse(['error' => 'Card not recognized.'], Response::HTTP_NOT_FOUND);
        }

        ['extId' => $extId] = $seen = ScannedCardMatcher::recognized($result);
        unset($seen['extId']);
        $recognized = $seen;
        $card = $this->matcher->match($game, $result);
        if ($card === null) {
            $this->logger->notice(sprintf(
                'Scanned %s card not in the catalog: %s (%s #%s, %s, ext_id %s)',
                $game->value, $recognized['title'], $recognized['set'], $recognized['number'], $recognized['lang'], $extId,
            ));

            return new JsonResponse(['error' => 'Card not in the catalog.', 'recognized' => $recognized], Response::HTTP_NOT_FOUND);
        }

        return new JsonResponse([
            'card' => [
                'id' => $card->id->toRfc4122(),
                'name' => $card->name,
                'number' => $card->number,
                'set' => ['code' => $card->set->code, 'name' => $card->set->name],
            ],
            'recognized' => $recognized,
        ]);
    }

    /** A field from the query string or the multipart form, whichever the app used. */
    private function param(Request $request, string $name, string $default): string
    {
        $value = $request->query->getString($name, $request->request->getString($name));

        return $value !== '' ? $value : $default;
    }
}
