<?php declare(strict_types=1);

namespace App\Games\Pokemon\Service;

use App\Contract\ImportDataTransformer;

class TCGDexDataTransformer implements ImportDataTransformer
{
    public function transformSet(array $raw): array
    {
        return [
            'code' => $raw['id'],
            'name' => $raw['name'],
            'type' => 'expansion',
            'block' => $raw['serie']['id'],
            'card_count' => $raw['cardCount']['total'],
            'released_at' => $raw['releaseDate'],
            'logo_uri' => isset($raw['logo']) ? $raw['logo'] . '.png' : null,
            'icon_uri' => isset($raw['symbol']) ? $raw['symbol'] . '.png' : null,
        ];
    }

    public function transformCard(array $raw): array
    {
        return [
            'name' => $raw['name'],
            'lang' => $raw['lang'],
            'number' => $raw['localId'],
            'rarity' => $raw['rarity'],
            'artist' => $raw['illustrator'] ?? null,
            'type_line' => $raw['category'],
            'oracle_text' => null,
            'flavor_text' => $raw['description'] ?? null,
            'set_code' => $raw['set']['id'],
            'image_uri' => isset($raw['image']) ? $raw['image'] . '/high.png' : null,
            'details' => [
                'unique_id' => hash('xxh3', "{$raw['id']}|{$raw['lang']}"),
                'finishes' => $this->getFinishes($raw['variants'] ?? []),
                'regulation_mark' => $raw['regulationMark'] ?? null,
                'legalities' => $raw['legal'] ?? [],
                ...match ($raw['category']) {
                    'Trainer' => ['trainer' => $this->getTrainerDetails($raw)],
                    'Energy' => ['energy' => $this->getEnergyDetails($raw)],
                    default => ['pokemon' => $this->getPokemonDetails($raw)],
                },
            ],
        ];
    }

    private function getPokemonDetails(array $raw): array
    {
        return [
            'dex_ids' => $raw['dexId'] ?? null,
            'hp' => $raw['hp'] ?? null,
            'colors' => $raw['types'] ?? [],
            'stage' => $raw['stage'] ?? null,
            'evolve_from' => $raw['evolveFrom'] ?? null,
            'level' => $raw['level'] ?? null,
            'suffix' => $raw['suffix'] ?? null,
            'item' => $raw['item'] ?? null,
            'abilities' => $raw['abilities'] ?? [],
            'attacks' => $raw['attacks'] ?? [],
            'weaknesses' => $raw['weaknesses'] ?? [],
            'resistances' => $raw['resistances'] ?? [],
            'retreat' => $raw['retreat'] ?? null,
        ];
    }

    private function getTrainerDetails(array $raw): array
    {
        return [
            'trainer_type' => $raw['trainerType'] ?? null,
            'effect' => $raw['effect'] ?? null,
        ];
    }

    private function getEnergyDetails(array $raw): array
    {
        return [
            'energy_type' => $raw['energyType'] ?? null,
            'effect' => $raw['effect'] ?? null,
        ];
    }

    private function getFinishes(array $raw): array
    {
        $finishes = [];
        foreach ($raw as $key => $value) {
            if ($value === true) {
                $finishes[] = $key;
            }
        }

        return $finishes;
    }
}
