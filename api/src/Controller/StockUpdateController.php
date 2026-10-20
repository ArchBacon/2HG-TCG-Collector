<?php declare(strict_types=1);

namespace App\Controller;

use App\Enum\Game;
use App\Service\StockUpdateService;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use function hash_equals;
use function is_array;
use function is_string;

/**
 * Receives stock updates from the web shop. Authenticated with a shared secret in the
 * `X-Stock-Token` header (env STOCK_UPDATE_TOKEN); the route is disabled while that's unset.
 *
 * PROVISIONAL body, until the real feed format is known:
 *   {"game": "mtg", "products": [{"productId": "123", "name": "...", "stock": 4, "price": 1.25}]}
 */
#[Route('/api/stock')]
final class StockUpdateController
{
    public function __construct(
        private readonly StockUpdateService $stockUpdates,
        #[Autowire(env: 'STOCK_UPDATE_TOKEN')]
        private readonly string $token,
    ) {}

    #[Route('', methods: ['POST'])]
    public function update(Request $request): JsonResponse
    {
        $sent = $request->headers->get('X-Stock-Token') ?? '';
        if ($this->token === '' || !hash_equals($this->token, $sent)) {
            return new JsonResponse(['error' => 'Invalid stock token.'], Response::HTTP_UNAUTHORIZED);
        }

        $data = json_decode($request->getContent(), true);
        if (!is_array($data)) {
            return new JsonResponse(['error' => 'Invalid JSON body.'], Response::HTTP_BAD_REQUEST);
        }

        $game = is_string($data['game'] ?? null) ? Game::tryFrom($data['game']) : null;
        if ($game === null) {
            return new JsonResponse(['error' => 'Missing or invalid "game".'], Response::HTTP_BAD_REQUEST);
        }

        if (!is_array($data['products'] ?? null)) {
            return new JsonResponse(['error' => 'Missing or invalid "products".'], Response::HTTP_BAD_REQUEST);
        }

        return new JsonResponse($this->stockUpdates->apply($game->value, $data['products']));
    }
}
