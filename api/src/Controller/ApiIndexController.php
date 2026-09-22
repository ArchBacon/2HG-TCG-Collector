<?php declare(strict_types=1);

namespace App\Controller;

use App\Enum\Game;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

/*
 * ✦ ── AI-GENERATED CODE ────────────────────────────────────────────── ✦
 *   This was written by an AI assistant, not by hand. Beep boop.
 * ✦ ─────────────────────────────────────────────────────────────────── ✦
 */

/**
 * Handwritten index endpoints for the API root and each TCG's own prefix (e.g. /api/mtg).
 * API Platform doesn't cover either on its own: hitting /api falls through to its generic Hydra
 * entrypoint, which is broken here since every game's Card/Set share the same Hydra short name
 * (only the last-registered game's collection links survive); and /api/mtg (with no further
 * path segment) simply has no route at all, so it 404s.
 */
final class ApiIndexController
{
    #[Route('/api', name: 'app_api_root', methods: ['GET'], priority: 10)]
    public function root(): JsonResponse
    {
        $tcgs = [];
        foreach (Game::cases() as $game) {
            $tcgs[$game->value] = '/api/' . $game->value;
        }

        return new JsonResponse([
            'message' => 'Welcome to the TCG Collector API. See "tcgs" for the available trading card games.',
            'tcgs' => $tcgs,
        ]);
    }

    /**
     * Priority is deliberately low: this only fires once none of API Platform's own /api/*
     * routes (the resource collections themselves, docs, contexts, validation_errors, ...)
     * claim the path first.
     */
    #[Route('/api/{game}', name: 'app_api_game_index', methods: ['GET'], priority: -100)]
    public function gameIndex(string $game): JsonResponse
    {
        if (Game::tryFrom($game) === null) {
            return new JsonResponse([
                'message' => sprintf('Unknown TCG "%s". See "tcgs" at /api for the available ones.', $game),
            ], Response::HTTP_NOT_FOUND);
        }

        return new JsonResponse([
            'message' => sprintf('Available routes for "%s".', $game),
            'routes' => [
                'cards' => '/api/' . $game . '/cards',
                'sets' => '/api/' . $game . '/sets',
            ],
        ]);
    }
}
