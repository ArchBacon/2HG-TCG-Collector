<?php declare(strict_types=1);

namespace App\Games\MTG\Service;

/**
 * Shapes a raw Scryfall bulk-data card JSON row into the per-face arrays
 * {@see ScryfallImportService} denormalizes into {@see \App\Games\MTG\Entity\Card} entities.
 */
final class ScryfallCardFaceExtractor
{
    /** @return list<string> */
    public function extractRelatedScryfallIds(array $data): array
    {
        $ids = [];
        foreach ($data['all_parts'] ?? [] as $part) {
            if ($part['component'] !== 'combo_piece') {
                $ids[] = $part['id'];
            }
        }

        return $ids;
    }

    /** @return list<string> */
    public function extractVariantScryfallIds(array $data): array
    {
        if (($data['variation'] ?? false) && isset($data['variant_of'])) {
            return [$data['variant_of']];
        }

        return [];
    }

    public function extractFaces(array $data, array $relatedIds, array $variantIds): array
    {
        $sharedFaceData = [
            'related' => $relatedIds,
            'variants' => $variantIds,
            'details' => [
                'scryfall_id' => $data['id'],
                'layout' => $data['layout'],
                'cmc' => $data['cmc'] ?? null,
                'colors' => $data['color_identity'],
                'legalities' => $data['legalities'],
                'finishes' => $data['finishes'],
                'oversized' => $data['oversized'],
                'promo' => $data['promo'],
                'frame' => $data['frame'],
            ],
        ];

        $faceList = $data['card_faces'] ?? [$data];
        // each face falls back to the whole-card data first (lang, collector_number, rarity,
        // image_uris, ... aren't repeated per face by Scryfall), then the face's own fields
        // (name, type_line, oracle_text, ...) take priority over it
        return array_map(
            fn (array $faceData) => $this->makeCardFace($sharedFaceData, array_merge($data, $faceData)),
            $faceList,
        );
    }

    private function makeCardFace(array $face, array $data): array
    {
        $newFace = array_merge($data, $face);
        $newFace['mana_cost'] = $data['mana_cost'] ?? null;
        $newFace['power'] = $data['power'] ?? null;
        $newFace['toughness'] = $data['toughness'] ?? null;
        $newFace['loyalty'] = $data['loyalty'] ?? null;
        $newFace['artist'] = $data['artist'] ?? null;
        $newFace['image_uri'] = $data['image_uris']['png'] ?? null;

        return $newFace;
    }
}
