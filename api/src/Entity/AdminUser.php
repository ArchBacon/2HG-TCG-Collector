<?php declare(strict_types=1);

namespace App\Entity;

use App\Repository\AdminUserRepository;
use Doctrine\ORM\Mapping as ORM;
use LogicException;
use Symfony\Component\Security\Core\User\PasswordAuthenticatedUserInterface;
use Symfony\Component\Security\Core\User\UserInterface;

/**
 * A back-office login for the /admin pages. Entirely separate from the anonymous app
 * {@see User}: different table, provider and firewall. Created with `api:admin:create`.
 */
#[ORM\Entity(repositoryClass: AdminUserRepository::class)]
#[ORM\Table(name: 'admin_user')]
class AdminUser implements UserInterface, PasswordAuthenticatedUserInterface
{
    #[ORM\Id]
    #[ORM\Column]
    #[ORM\GeneratedValue(strategy: 'AUTO')]
    public private(set) int $id;

    #[ORM\Column(type: 'string', length: 180, unique: true)]
    public string $username {
        get => $this->username;
        set => $this->username = $value;
    }

    #[ORM\Column(type: 'string', length: 255)]
    public string $password {
        get => $this->password;
        set => $this->password = $value;
    }

    public function __construct(string $username)
    {
        $this->username = $username;
    }

    public function getPassword(): string
    {
        return $this->password;
    }

    public function getRoles(): array
    {
        return ['ROLE_ADMIN'];
    }

    public function getUserIdentifier(): string
    {
        if ($this->username === '') {
            throw new LogicException('Admin user has an empty username.');
        }

        return $this->username;
    }
}
