<?php declare(strict_types=1);

namespace App\Controller;

use App\Repository\CardListingRepository;
use App\Repository\UnmatchedProductRepository;
use InvalidArgumentException;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Uid\Uuid;
use function is_array;
use function is_numeric;
use function is_string;
use function sprintf;

/**
 * Example endpoint for an automatcher: post every product from the shop feed here. Products
 * for which the automatcher found a confident match (i.e. supplied `cardId` + `finish`) are
 * upserted into {@see \App\Entity\CardListing}; everything else is parked as an
 * {@see \App\Entity\UnmatchedProduct} for manual review, and cleared out of that table again
 * the moment a later call resolves it.
 */
#[Route('/api/card-listings')]
final class CardListingController
{
    public function __construct(
        private readonly CardListingRepository $listings,
        private readonly UnmatchedProductRepository $unmatched,
    ) {}

    #[Route('', methods: ['POST'])]
    public function upsert(Request $request): JsonResponse
    {
        $decoded = json_decode($request->getContent(), true);
        if (!is_array($decoded)) {
            return new JsonResponse(['error' => 'Invalid JSON body.'], Response::HTTP_BAD_REQUEST);
        }

        // A JSON body is always an object here (a JSON array would fail the checks below anyway,
        // since it can't carry string keys like "game"/"productId") - rebuild with proven string
        // keys so $data can be passed on as a real associative payload.
        $data = [];
        foreach ($decoded as $key => $value) {
            if (!is_string($key)) {
                return new JsonResponse(['error' => 'Invalid JSON body.'], Response::HTTP_BAD_REQUEST);
            }
            $data[$key] = $value;
        }

        foreach (['game', 'productId'] as $key) {
            if (!isset($data[$key]) || !is_string($data[$key])) {
                return new JsonResponse(['error' => sprintf('Missing or invalid "%s".', $key)], Response::HTTP_BAD_REQUEST);
            }
        }

        /** @var string $game */
        $game = $data['game'];
        /** @var string $productId */
        $productId = $data['productId'];

        // No confident match supplied - file it for manual review instead of guessing.
        if (!isset($data['cardId'], $data['finish']) || !is_string($data['cardId']) || !is_string($data['finish'])) {
            $unmatched = $this->unmatched->upsert(
                game: $game,
                productId: $productId,
                name: is_string($data['name'] ?? null) ? $data['name'] : $productId,
                payload: $data,
            );

            return new JsonResponse(['status' => 'unmatched', 'id' => $unmatched->id]);
        }

        try {
            $cardId = Uuid::fromString($data['cardId']);
        } catch (InvalidArgumentException) {
            return new JsonResponse(['error' => 'Invalid "cardId".'], Response::HTTP_BAD_REQUEST);
        }

        $stock = $data['stock'] ?? 0;
        $price = $data['price'] ?? 0.0;
        if (!is_numeric($stock) || !is_numeric($price)) {
            return new JsonResponse(['error' => 'Invalid "stock" or "price".'], Response::HTTP_BAD_REQUEST);
        }

        $listing = $this->listings->upsert(
            game: $game,
            productId: $productId,
            cardId: $cardId,
            finish: $data['finish'],
            stock: (int) $stock,
            price: (float) $price,
        );

        // This product may have previously been filed as unmatched; it's resolved now.
        $stale = $this->unmatched->findOneBy(['game' => $game, 'productId' => $productId]);
        if ($stale !== null) {
            $this->unmatched->remove($stale);
        }

        return new JsonResponse(['status' => 'matched', 'id' => $listing->id]);
    }
}
