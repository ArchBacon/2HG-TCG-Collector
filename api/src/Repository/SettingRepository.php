<?php declare(strict_types=1);

namespace App\Repository;

use App\Entity\Setting;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

/**
 * @extends ServiceEntityRepository<Setting>
 */
final class SettingRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, Setting::class);
    }

    /**
     * Sets the value of setting $name, making it when it doesn't exist yet.
     */
    public function set(string $name, string $value): Setting
    {
        $setting = $this->find($name);
        if ($setting === null) {
            $setting = new Setting($name, $value);
            $this->getEntityManager()->persist($setting);
        } else {
            $setting->value = $value;
        }
        $this->getEntityManager()->flush();

        return $setting;
    }
}
