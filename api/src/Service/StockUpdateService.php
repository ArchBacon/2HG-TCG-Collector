<?php declare(strict_types=1);

namespace App\Service;

use App\Entity\CardListing;
use App\Entity\UnmatchedProduct;
use App\Repository\CardListingRepository;
use App\Repository\UnmatchedProductRepository;
use Doctrine\ORM\EntityManagerInterface;
use function array_keys;
use function is_array;
use function is_numeric;
use function is_int;
use function is_string;

/**
 * Applies a web shop stock update. Products already linked to a card get their stock and price
 * updated; unknown products are parked as {@see UnmatchedProduct} (with the latest record as
 * payload) so they show up in the admin for manual linking.
 *
 * PROVISIONAL: the record shape (`productId`, `name`, `stock`, `price`) is a placeholder until
 * the real shop feed format is known.
 */
final readonly class StockUpdateService
{
    public function __construct(
        private CardListingRepository $listings,
        private UnmatchedProductRepository $unmatched,
        private EntityManagerInterface $entityManager,
    ) {}

    /**
     * @param array<mixed> $products
     * @return array{updated: int, unmatched: int, skipped: int}
     */
    public function apply(string $game, array $products): array
    {
        $result = ['updated' => 0, 'unmatched' => 0, 'skipped' => 0];

        // Keyed by productId; a later duplicate in the same update wins. Numeric ids become int
        // keys here (PHP array keys), hence the casts back to string below.
        /** @var array<array-key, array<string, mixed>> $records */
        $records = [];
        foreach ($products as $product) {
            $productId = is_array($product) ? $product['productId'] ?? null : null;
            if (!is_string($productId) && !is_int($productId)) {
                $result['skipped']++;
                continue;
            }
            /** @var array<string, mixed> $product */
            $records[(string) $productId] = $product;
        }

        if ($records === []) {
            return $result;
        }

        $productIds = array_map('strval', array_keys($records));
        $listings = $this->indexByProductId($this->listings->findBy(['game' => $game, 'productId' => $productIds]));
        $parked = $this->indexByProductId($this->unmatched->findBy(['game' => $game, 'productId' => $productIds]));

        foreach ($records as $productId => $record) {
            $productId = (string) $productId;
            $listing = $listings[$productId] ?? null;

            if ($listing !== null) {
                if (is_numeric($record['stock'] ?? null)) {
                    $listing->stock = (int) $record['stock'];
                }
                if (is_numeric($record['price'] ?? null)) {
                    $listing->price = (float) $record['price'];
                }
                $result['updated']++;
                continue;
            }

            $name = is_string($record['name'] ?? null) ? $record['name'] : $productId;
            $unmatched = $parked[$productId] ?? null;
            if ($unmatched === null) {
                $this->entityManager->persist(new UnmatchedProduct($game, $productId, $name, $record));
            } else {
                $unmatched->name = $name;
                $unmatched->payload = $record;
            }
            $result['unmatched']++;
        }

        $this->entityManager->flush();

        return $result;
    }

    /**
     * @template T of CardListing|UnmatchedProduct
     * @param array<T> $rows
     * @return array<string, T>
     */
    private function indexByProductId(array $rows): array
    {
        $indexed = [];
        foreach ($rows as $row) {
            $indexed[$row->productId] = $row;
        }

        return $indexed;
    }
}
