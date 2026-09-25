<?php declare(strict_types=1);

namespace App\Repository;

use App\Entity\CardList;
use App\Entity\User;
use App\Enum\CardListType;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

/**
 * @extends ServiceEntityRepository<CardList>
 */
final class CardListRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, CardList::class);
    }

    /**
     * @return list<CardList>
     */
    public function findByUser(User $user, ?CardListType $type = null): array
    {
        $criteria = ['user' => $user];
        if ($type !== null) {
            $criteria['type'] = $type;
        }

        return $this->findBy($criteria, ['createdAt' => 'ASC']);
    }
}
