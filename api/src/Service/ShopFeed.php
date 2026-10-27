<?php declare(strict_types=1);

namespace App\Service;

use function array_filter;
use function implode;
use function is_array;
use function is_int;
use function is_numeric;
use function is_string;
use function trim;

/**
 * Reads 2HG's stock feed (PrestaShop): products in categories, each with a variant per condition.
 *
 *   {"language": "en", "categories": [{"id_category": 320, "name": "Evolving Skies", "cards": [
 *     {"id_product": 53021, "name": "EVS 001 - Pinsir", "reference": "Evolving Skies", "price_excl_tax": 0.1,
 *      "variants": [{"id_product_attribute": 130279, "attributes": {"Card Condition": "Near Mint"},
 *                    "price_excl_tax": 0.1, "stock": 30}, ...], "total_stock": 30}, ...]}]}
 *
 * Doesn't say which game a product is for; {@see ProductMatcher} finds that from its set.
 *
 * @phpstan-type ShopCondition array{variantId: string, condition: string, stock: int, price: float}
 * @phpstan-type ShopProduct array{productId: string, name: string, set: string, conditions: list<ShopCondition>, record: array<string, mixed>}
 */
final class ShopFeed
{
    /** The variant attribute that holds the condition. */
    private const string CONDITION_ATTRIBUTE = 'Card Condition';

    /**
     * The products in $feed. Records without a product id are counted as skipped.
     *
     * @param array<mixed> $feed
     *
     * @return array{language: ?string, products: list<ShopProduct>, skipped: int}
     */
    public static function read(array $feed): array
    {
        $products = [];
        $skipped = 0;

        foreach (is_array($feed['categories'] ?? null) ? $feed['categories'] : [] as $category) {
            if (!is_array($category)) {
                continue;
            }
            $categoryName = is_string($category['name'] ?? null) ? trim($category['name']) : '';

            foreach (is_array($category['cards'] ?? null) ? $category['cards'] : [] as $record) {
                $product = is_array($record) ? self::product(self::stringKeys($record), $categoryName) : null;
                if ($product === null) {
                    $skipped++;
                    continue;
                }
                $products[] = $product;
            }
        }

        return [
            'language' => is_string($feed['language'] ?? null) ? $feed['language'] : null,
            'products' => $products,
            'skipped' => $skipped,
        ];
    }

    /**
     * The conditions of a product record: one per variant. A product without variants has none.
     *
     * @param array<mixed> $record
     *
     * @return list<ShopCondition>
     */
    public static function conditions(array $record): array
    {
        $conditions = [];
        foreach (is_array($record['variants'] ?? null) ? $record['variants'] : [] as $variant) {
            $variantId = is_array($variant) ? self::id($variant['id_product_attribute'] ?? null) : null;
            if (!is_array($variant) || $variantId === null) {
                continue;
            }

            $attributes = array_filter(is_array($variant['attributes'] ?? null) ? $variant['attributes'] : [], is_string(...));
            $condition = $attributes[self::CONDITION_ATTRIBUTE] ?? implode(' / ', $attributes);
            $stock = $variant['stock'] ?? 0;
            $price = $variant['price_excl_tax'] ?? $record['price_excl_tax'] ?? 0;

            $conditions[] = [
                'variantId' => $variantId,
                'condition' => trim($condition) !== '' ? trim($condition) : 'Default',
                'stock' => is_numeric($stock) ? max(0, (int) $stock) : 0,
                'price' => is_numeric($price) ? (float) $price : 0.0,
            ];
        }

        return $conditions;
    }

    /**
     * @param array<string, mixed> $record
     *
     * @return ?ShopProduct
     */
    private static function product(array $record, string $categoryName): ?array
    {
        $productId = self::id($record['id_product'] ?? null);
        if ($productId === null) {
            return null;
        }

        $reference = is_string($record['reference'] ?? null) ? trim($record['reference']) : '';

        return [
            'productId' => $productId,
            'name' => is_string($record['name'] ?? null) ? trim($record['name']) : $productId,
            'set' => $reference !== '' ? $reference : $categoryName,
            'conditions' => self::conditions($record),
            'record' => $record,
        ];
    }

    private static function id(mixed $value): ?string
    {
        return is_int($value) || (is_string($value) && trim($value) !== '') ? trim((string) $value) : null;
    }

    /**
     * @param array<mixed> $array
     *
     * @return array<string, mixed>
     */
    private static function stringKeys(array $array): array
    {
        $result = [];
        foreach ($array as $key => $value) {
            $result[(string) $key] = $value;
        }

        return $result;
    }
}
