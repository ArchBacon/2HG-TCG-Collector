<?php declare(strict_types=1);

namespace App\Games\OnePiece\Service;

use App\Contract\ImportDataTransformer;

class OPTCGAPIDataTransformer implements ImportDataTransformer
{
    public function transformSet(array $raw): array
    {
        return [
            'code' => $raw['set_id'],
            'name' => $raw['set_name'],
            'type' => 'expansion',
            'card_count' => null,
            'released_at' => null,
        ];
    }

    public function transformCard(array $raw): array
    {
        return [
            'name' => $raw['card_name'],
            'number' => $raw['card_set_id'],
            'rarity' => $raw['rarity'],
            'artist' => null,
            'type_line' => $raw['card_type'],
            'oracle_text' => $this->sanitizeText($raw['card_text']),
            'flavor_text' => null,
            'set_code' => $raw['set_id'],
            'image_uri' => $raw['card_image'],
            'details' => [
                'unique_id' => hash('xxh3', "{$raw['set_id']}|{$raw['card_image_id']}|{$raw['card_image']}"),
                'color' => $raw['card_color'],
                'cost' => $this->sanitizeDigit($raw['card_cost']),
                'power' => $this->sanitizeDigit($raw['card_power']),
                'life' => $this->sanitizeDigit($raw['life']),
                'counter_amount' => $this->sanitizeDigit($raw['counter_amount']),
                'attribute' => $this->sanitizeText($raw['attribute']),
                'sub_types' => $raw['sub_types'],
            ],
        ];
    }

    private function sanitizeDigit(null|string|int $number): ?int
    {
        if ($number !== null && $number !== 'NULL') {
            return (int)$number;
        }

        return null;
    }

    private function sanitizeText(?string $string): ?string
    {
        if ($string !== null && $string !== 'NULL') {
            return $string;
        }

        return null;
    }
}
