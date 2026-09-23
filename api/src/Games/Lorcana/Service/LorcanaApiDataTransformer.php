<?php declare(strict_types=1);

namespace App\Games\Lorcana\Service;

use App\Contract\ImportDataTransformer;

class LorcanaApiDataTransformer implements ImportDataTransformer
{
    public function transformSet(array $raw): array
    {
        return [
            'code' => strtolower($raw['Set_ID']),
            'name' => $raw['Name'],
            'type' => 'expansion',
            'card_count' => $raw['Cards'],
            'released_at' => $raw['Release_Date'],
        ];
    }

    public function transformCard(array $raw): array
    {
        return [
            'name' => $raw['Name'],
            'number' => (string)$raw['Card_Num'],
            'rarity' => $raw['Rarity'],
            'artist' => $raw['Artist'],
            'type_line' => $raw['Type'],
            'oracle_text' => $raw['Body_Text'] ?? null,
            'flavor_text' => $raw['Flavor_Text'] ?? null,
            'set_code' => $raw['Set_ID'],
            'image_uri' => $raw['Image'],
            'details' => [
                'unique_id' => $raw['Unique_ID'],
                'color' => $raw['Color'],
                'cost' => $raw['Cost'],
                'inkable' => $raw['Inkable'],
                'classifications' => $raw['Classifications'] ?? null,
                'abilities' => $raw['Abilities'] ?? null,
                'strength' => $raw['Strength'] ?? null,
                'willpower' => $raw['Willpower'] ?? null,
                'lore' => $raw['Lore'] ?? null,
                'franchise' => $raw['Franchise'] === "" ? null : $raw['Franchise'],
            ],
        ];
    }
}
