<?php declare(strict_types=1);

namespace App\Games\MTG\Service;

use App\Contract\ImportDataTransformer;

final class ScryfallDataTransformer implements ImportDataTransformer
{
    /** @inheritDoc */
    public function transformSet(array $raw): array
    {
        $raw['type'] = $raw['set_type'];
        $raw['block'] = $raw['block_code'] ?? null;

        return $raw;
    }

    /** @inheritDoc */
    public function transformCard(array $raw): array
    {
        $raw['scryfall_id'] = $raw['id'];
        $raw['number'] = $raw['collector_number'];
        $raw['oracle_text'] = $raw['oracle_text'] ?? $raw['card_faces'][0]['oracle_text'] ?? null;
        $raw['colors'] = $raw['color_identity'];

        // Scryfall's own id here, not ours — ScryfallImportService resolves these to internal
        // ids once the related cards exist, since that requires a DB lookup this class can't do.
        $raw['related'] = [];
        foreach ($raw['all_parts'] ?? [] as $part) {
            if ($part['component'] !== 'combo_piece') {
                $raw['related'][] = $part['id'];
            }
        }

        unset($raw['id'], $raw['set']);

        $faces = $raw['card_faces'] ?? [];
        unset($raw['card_faces']);

        return [$raw, $faces];
    }

    /**
     * Buckets the {@see \App\Games\MTG\Entity\CardDetails} fields into a nested `details` key —
     * the generic denormalizer won't route flat keys into a Doctrine embedded object's
     * properties on its own. Takes the already face-merged data (front/back overrides for
     * mana_cost/power/toughness/loyalty/cmc must be applied first — those genuinely differ per
     * face; layout/legalities/finishes/oversized/promo/frame/color_identity are whole-card
     * attributes Scryfall never duplicates per face).
     *
     * @param array<string, mixed> $merged
     * @return array<string, mixed>
     */
    public function withDetails(array $merged): array
    {
        $merged['details'] = [
            'scryfall_id' => $merged['scryfall_id'],
            'layout' => $merged['layout'],
            'mana_cost' => $merged['mana_cost'] ?? null,
            'cmc' => $merged['cmc'] ?? null,
            'colors' => $merged['color_identity'] ?? [],
            'power' => $merged['power'] ?? null,
            'toughness' => $merged['toughness'] ?? null,
            'loyalty' => $merged['loyalty'] ?? null,
            'legalities' => $merged['legalities'] ?? [],
            'finishes' => $merged['finishes'] ?? [],
            'oversized' => $merged['oversized'] ?? false,
            'promo' => $merged['promo'] ?? false,
            'frame' => $merged['frame'],
        ];

        return $merged;
    }
}
