<?php declare(strict_types=1);

namespace App\DataFixtures;

use App\Entity\AdminUser;
use Doctrine\Bundle\FixturesBundle\Fixture;
use Doctrine\Persistence\ObjectManager;
use RuntimeException;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface;

/**
 * Seeds the first admin login from ADMIN_USERNAME / ADMIN_PASSWORD (e.g. in .env.local).
 * Further admins (or password resets) go through `api:admin:create`.
 */
class AdminUserFixtures extends Fixture
{
    public function __construct(
        private readonly UserPasswordHasherInterface $hasher,
        #[Autowire(env: 'ADMIN_USERNAME')]
        private readonly string $username,
        #[Autowire(env: 'ADMIN_PASSWORD')]
        private readonly string $password,
    ) {
    }

    public function load(ObjectManager $manager): void
    {
        if ($this->username === '' || $this->password === '') {
            throw new RuntimeException('Set ADMIN_USERNAME and ADMIN_PASSWORD (e.g. in .env.local) to create the first admin login.');
        }

        $admin = $manager->getRepository(AdminUser::class)->findOneBy(['username' => $this->username]);
        if ($admin === null) {
            $admin = new AdminUser($this->username);
            $manager->persist($admin);
        }

        $admin->password = $this->hasher->hashPassword($admin, $this->password);
        $manager->flush();
    }
}
