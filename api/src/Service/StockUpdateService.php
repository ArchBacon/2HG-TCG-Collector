<?php declare(strict_types=1);

namespace App\Service;

use App\Entity\CardListing;
use App\Entity\UnmatchedProduct;
use App\Enum\Language;
use App\Repository\CardListingRepository;
use App\Repository\UnmatchedProductRepository;
use Doctrine\ORM\EntityManagerInterface;
use function array_chunk;
use function array_column;
use function count;
use function is_string;
use function sprintf;

/**
 * Applies a stock update from the web shop ({@see ShopFeed}). Products already linked to a card
 * get their conditions (stock, price) updated. New products are linked when
 * {@see ProductMatcher} finds their card; the others are parked as {@see UnmatchedProduct}, with
 * the latest record and the reason, for manual linking in the admin.
 *
 * An update may hold only some products: the ones it leaves out stay as they are.
 *
 * @phpstan-import-type ShopProduct from ShopFeed
 * @phpstan-type StockUpdateResult array{products: int, updated: int, linked: int, unmatched: int, skipped: int}
 */
final readonly class StockUpdateService
{
    /** Products handled per flush, to keep memory flat on a full export. */
    private const int CHUNK_SIZE = 500;

    public function __construct(
        private CardListingRepository $listings,
        private UnmatchedProductRepository $unmatched,
        private ProductMatcher $matcher,
        private EntityManagerInterface $entityManager,
    ) {}

    /**
     * @param array<mixed> $feed
     *
     * @return StockUpdateResult
     */
    public function apply(array $feed): array
    {
        $read = ShopFeed::read($feed);
        $lang = is_string($read['language']) ? Language::tryFrom($read['language']) : null;
        $result = ['products' => count($read['products']), 'updated' => 0, 'linked' => 0, 'unmatched' => 0, 'skipped' => $read['skipped']];

        foreach (array_chunk($read['products'], self::CHUNK_SIZE) as $chunk) {
            $this->applyChunk($chunk, $lang, $result);
            $this->entityManager->flush();
            $this->entityManager->clear();
        }

        return $result;
    }

    /**
     * @param list<ShopProduct> $products
     * @param StockUpdateResult $result
     */
    private function applyChunk(array $products, ?Language $lang, array &$result): void
    {
        $productIds = array_column($products, 'productId');
        $listings = $this->indexByProductId($this->listings->findBy(['productId' => $productIds]));
        $parked = $this->indexByProductId($this->unmatched->findBy(['productId' => $productIds]));

        foreach ($products as $product) {
            $productId = $product['productId'];

            $listing = $listings[$productId] ?? null;
            if ($listing !== null) {
                $listing->syncConditions($product['conditions']);
                $result['updated']++;
                continue;
            }

            $match = $this->matcher->match($product['name'], $product['set'], $lang);
            $reason = $match->reason;
            if ($match->game !== null && $match->cardId !== null && $match->finish !== null) {
                $taken = $this->listings->findOneBy(['game' => $match->game->value, 'cardId' => $match->cardId, 'finish' => $match->finish]);
                if ($taken === null) {
                    $listing = new CardListing($match->game->value, $match->cardId, $match->finish, $productId);
                    $listing->syncConditions($product['conditions']);
                    $this->entityManager->persist($listing);
                    $this->entityManager->flush(); // So the next product sees this card + finish as taken
                    $listings[$productId] = $listing; // In case the update has it twice

                    if (isset($parked[$productId])) {
                        $this->entityManager->remove($parked[$productId]);
                        unset($parked[$productId]);
                    }
                    $result['linked']++;
                    continue;
                }
                $reason = sprintf('Its card (%s) is already linked to product %s.', $match->finish, $taken->productId);
            }

            $unmatched = $parked[$productId] ?? null;
            if ($unmatched === null) {
                $unmatched = new UnmatchedProduct($match->game?->value, $productId, $product['name']);
                $this->entityManager->persist($unmatched);
                $parked[$productId] = $unmatched;
            }
            $unmatched->game = $match->game->value ?? $unmatched->game;
            $unmatched->name = $product['name'];
            $unmatched->reason = $reason;
            $unmatched->payload = $product['record'];
            $result['unmatched']++;
        }
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
