<?php declare(strict_types=1);

namespace App\Controller;

use App\Service\StockTokenService;
use App\Service\StockUpdateService;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use function is_array;

/**
 * Receives stock updates pushed by the web shop. Authenticated with a shared secret in the
 * `X-Stock-Token` header, generated in the admin ({@see StockTokenService}); the route refuses
 * everything while there's none.
 *
 * The body is the shop's own export: products in categories, with a variant per condition (see
 * {@see \App\Service\ShopFeed}). Answers with counts: products updated, newly linked, unmatched
 * (for the admin to link) and skipped (no product id).
 */
#[Route('/api/stock')]
final class StockUpdateController
{
    public function __construct(
        private readonly StockUpdateService $stockUpdates,
        private readonly StockTokenService $tokens,
    ) {}

    #[Route('', methods: ['POST'])]
    public function update(Request $request): JsonResponse
    {
        if (!$this->tokens->isValid($request->headers->get('X-Stock-Token') ?? '')) {
            return new JsonResponse(['error' => 'Invalid stock token.'], Response::HTTP_UNAUTHORIZED);
        }

        $data = json_decode($request->getContent(), true);
        if (!is_array($data)) {
            return new JsonResponse(['error' => 'Invalid JSON body.'], Response::HTTP_BAD_REQUEST);
        }

        if (!is_array($data['categories'] ?? null)) {
            return new JsonResponse(['error' => 'Missing or invalid "categories".'], Response::HTTP_BAD_REQUEST);
        }

        $result = $this->stockUpdates->apply($data);
        $this->tokens->recordUpdate($result);

        return new JsonResponse($result);
    }
}
