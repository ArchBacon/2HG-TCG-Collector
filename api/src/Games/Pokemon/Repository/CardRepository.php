<?php declare(strict_types=1);

namespace App\Games\Pokemon\Repository;

use App\Games\Pokemon\Entity\Card;
use App\Games\Pokemon\Entity\Set;
use App\Games\Pokemon\Enum\Language;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;
use Symfony\Component\Uid\Uuid;

/**
 * @extends ServiceEntityRepository<Card>
 */
final class CardRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, Card::class);
    }

    /**
     * Ids and image URIs only, not full entities — for callers that just need to enqueue image
     * jobs for every card of a set without paying to hydrate (and never detach — see the caller)
     * each one.
     *
     * Binds $set->id with an explicit 'uuid' type rather than the Set entity itself:
     * setParameter('set', $set) doesn't run the uuid column type's convertToDatabaseValue() for
     * an association comparison the way Criteria-based findBy() does, and silently matches zero
     * rows instead of erroring — binding the scalar id directly with an explicit type sidesteps
     * that entirely. Unlike scalar hydration, array hydration (used here) does run each column's
     * convertToPHPValue(), so `id` comes back as a real Uuid, not a raw binary string.
     *
     * @return array<string, ?string> card id (RFC 4122 string) => imageUri
     */
    public function findImageUrisBySetAndLang(Set $set, Language $lang): array
    {
        $rows = $this->createQueryBuilder('c')
            ->select('c.id', 'c.imageUri')
            ->where('c.set = :setId')
            ->andWhere('c.lang = :lang')
            ->setParameter('setId', $set->id, 'uuid')
            ->setParameter('lang', $lang)
            ->getQuery()
            ->getArrayResult();

        $imageUris = [];
        foreach ($rows as $row) {
            \assert($row['id'] instanceof Uuid);
            $imageUris[$row['id']->toRfc4122()] = $row['imageUri'];
        }

        return $imageUris;
    }

    /**
     * Returns every language's row for each id (see {@see Card::$lang}), not one per id.
     *
     * @param list<string> $tcgdexIds
     * @return list<Card>
     */
    public function findByTcgdexIds(array $tcgdexIds): array
    {
        if ($tcgdexIds === []) {
            return [];
        }

        return $this->createQueryBuilder('c')
            ->where('c.tcgdexId IN (:ids)')
            ->setParameter('ids', array_unique($tcgdexIds))
            ->getQuery()
            ->getResult();
    }
}
