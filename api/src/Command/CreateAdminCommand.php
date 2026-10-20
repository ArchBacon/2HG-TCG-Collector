<?php declare(strict_types=1);

namespace App\Command;

use App\Entity\AdminUser;
use App\Repository\AdminUserRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;
use Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface;
use function assert;
use function is_string;
use function sprintf;

/**
 * Creates an admin login, or resets the password of an existing one.
 */
#[AsCommand(name: 'api:admin:create', description: 'Create an admin login (or reset its password).')]
class CreateAdminCommand extends Command
{
    public function __construct(
        private readonly AdminUserRepository $admins,
        private readonly EntityManagerInterface $entityManager,
        private readonly UserPasswordHasherInterface $hasher,
    ) {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this->addArgument('username', InputArgument::REQUIRED, 'Login name.');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);
        $username = $input->getArgument('username');
        assert(is_string($username));

        $password = $io->askHidden('Password', static function (mixed $value): string {
            if (!is_string($value) || strlen($value) < 8) {
                throw new \RuntimeException('Use at least 8 characters.');
            }
            return $value;
        });
        assert(is_string($password));

        $admin = $this->admins->findOneBy(['username' => $username]);
        $isNew = $admin === null;
        if ($isNew) {
            $admin = new AdminUser($username);
            $this->entityManager->persist($admin);
        }

        $admin->password = $this->hasher->hashPassword($admin, $password);
        $this->entityManager->flush();

        $io->success(sprintf($isNew ? 'Created admin "%s".' : 'Reset password for admin "%s".', $username));

        return Command::SUCCESS;
    }
}
