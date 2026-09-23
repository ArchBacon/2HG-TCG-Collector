<?php declare(strict_types=1);

namespace App\Games\DragonBallFusion\Service;

use App\Contract\ImportDataTransformer;

class ApiTCGDataTransformer implements ImportDataTransformer
{
    public function transformSet(array $raw): array
    {
        return [
            'code' => $raw['set']['id'],
            'name' => $raw['set']['name'],
            'type' => 'expansion',
            'card_count' => null,
            'released_at' => null,
        ];
    }

    public function transformCard(array $raw): array
    {
        return [
            'name' => $raw['name'],
            'number' => $raw['code'],
            'rarity' => $raw['rarity'] === '' ? null : $raw['rarity'],
            'artist' => null,
            'type_line' => $raw['cardType'],
            'oracle_text' => $raw['effect'] === '-' ? null : $raw['effect'],
            'flavor_text' => null,
            'set_code' => $raw['set']['id'],
            'image_uri' => $raw['images']['large'],
            'details' => [
                'color' => $raw['color'],
                'cost' => $raw['cost'] === '-' ? null : (int)$raw['cost'],
                'specified_cost' => $raw['specifiedCost'] === '-' ? null : $raw['specifiedCost'],
                'power' => $raw['power'] === '-' ? null : (int)$raw['power'],
                'combo_power' => $raw['comboPower'] === '-' ? null : (int)$raw['comboPower'],
                'features' => $raw['features'] ?? null,
            ],
        ];
    }
}
