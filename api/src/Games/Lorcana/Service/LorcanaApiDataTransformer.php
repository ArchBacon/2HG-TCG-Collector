<?php declare(strict_types=1);

namespace App\Games\Lorcana\Service;

class LorcanaApiDataTransformer
{
    public function transformSetData(array $data): array
    {
        return [
            'code' => strtolower($data['Set_ID']),
            'name' => $data['Name'],
            'type' => 'expansion',
            'card_count' => $data['Cards'],
            'released_at' => $data['Release_Date'],
        ];
    }

    public function transformCardData(array $data): array
    {
        return [
            'name' => $data['Name'],
            'number' => (string)$data['Card_Num'],
            'rarity' => $data['Rarity'],
            'artist' => $data['Artist'],
            'type_line' => $data['Type'],
            'oracle_text' => $data['Body_Text'] ?? null,
            'flavor_text' => $data['Flavor_Text'] ?? null,
            'set_code' => $data['Set_ID'],
            'image_uri' => $data['Image'],
            'details' => [
                'unique_id' => $data['Unique_ID'],
                'color' => $data['Color'],
                'cost' => $data['Cost'],
                'inkable' => $data['Inkable'],
                'classifications' => $data['Classifications'] ?? null,
                'abilities' => $data['Abilities'] ?? null,
                'strength' => $data['Strength'] ?? null,
                'willpower' => $data['Willpower'] ?? null,
                'lore' => $data['Lore'] ?? null,
                'franchise' => $data['Franchise'] === "" ? null : $data['Franchise'],
            ],
        ];
    }
}
