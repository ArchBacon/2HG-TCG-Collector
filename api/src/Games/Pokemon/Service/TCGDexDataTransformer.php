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

    /**
     * A card's market prices from TCGdex's `pricing`, per our finish:
     * - Cardmarket, EUR: its trend (else its average). Cardmarket has one product per card, with
     *   a price and a "-holo" price: the card's own finish (normal, or holo for a holo rare) and
     *   its reverse holo.
     * - TCGplayer, USD: its market price (else the mid) per its finish.
     *
     * @param array<string, mixed> $raw a TCGdex card
     *
     * @return list<array{source: string, finish: string, currency: string, price: float, updatedAt: ?\DateTimeImmutable}>
     */
    public function transformPrices(array $raw): array
    {
        $finishes = $this->getFinishes($raw['variants'] ?? []);
        $pricing = $raw['pricing'] ?? [];
        $prices = [];

        $cardmarket = $pricing['cardmarket'] ?? null;
        if (is_array($cardmarket)) {
            $updatedAt = self::date($cardmarket['updated'] ?? null);
            $own = in_array('normal', $finishes, true) || !in_array('holo', $finishes, true) ? 'normal' : 'holo';
            foreach ([$own => '', 'reverse' => '-holo'] as $finish => $suffix) {
                if ($suffix !== '' && !in_array('reverse', $finishes, true)) {
                    continue; // Its "-holo" price is for a reverse holo it doesn't come in
                }
                $value = $cardmarket['trend' . $suffix] ?? $cardmarket['avg' . $suffix] ?? null;
                if (is_numeric($value)) {
                    $prices[] = ['source' => 'cardmarket', 'finish' => $finish, 'currency' => (string) ($cardmarket['unit'] ?? 'EUR'), 'price' => (float) $value, 'updatedAt' => $updatedAt];
                }
            }
        }

        $tcgplayer = $pricing['tcgplayer'] ?? null;
        if (is_array($tcgplayer)) {
            $updatedAt = self::date($tcgplayer['updated'] ?? null);
            foreach ($tcgplayer as $variant => $values) {
                if (!is_array($values)) {
                    continue; // `unit`, `updated`
                }
                $finish = match (true) {
                    str_contains($variant, 'reverse') => 'reverse',
                    str_starts_with($variant, '1st') => 'firstEdition',
                    $variant === 'holofoil' => 'holo',
                    $variant === 'normal' => 'normal',
                    default => null,
                };
                $value = $values['marketPrice'] ?? $values['midPrice'] ?? null;
                if ($finish !== null && is_numeric($value)) {
                    $prices[] = ['source' => 'tcgplayer', 'finish' => $finish, 'currency' => (string) ($tcgplayer['unit'] ?? 'USD'), 'price' => (float) $value, 'updatedAt' => $updatedAt];
                }
            }
        }

        return $prices;
    }

    private static function date(mixed $value): ?\DateTimeImmutable
    {
        if (!is_string($value)) {
            return null;
        }
        try {
            return new \DateTimeImmutable($value);
        } catch (\Exception) {
            return null;
        }
    }
}
