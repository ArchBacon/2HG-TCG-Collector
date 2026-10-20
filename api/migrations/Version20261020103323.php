<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20261020103323 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Admin logins, seeded with the first admin from ADMIN_USERNAME / ADMIN_PASSWORD.';
    }

    public function up(Schema $schema): void
    {
        // Every install runs this, so it's where the first admin gets created. Further admins
        // (or password resets) go through `api:admin:create`.
        $username = $this->env('ADMIN_USERNAME');
        $password = $this->env('ADMIN_PASSWORD');
        $this->abortIf(
            $username === '' || $password === '',
            'Set ADMIN_USERNAME and ADMIN_PASSWORD (e.g. in .env.local) to create the first admin login.',
        );

        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE admin_user (id INT AUTO_INCREMENT NOT NULL, username VARCHAR(180) NOT NULL, password VARCHAR(255) NOT NULL, UNIQUE INDEX UNIQ_AD8A54A9F85E0677 (username), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');

        // Same native hash the 'auto' password hasher produces; it rehashes on login if its
        // settings ever differ (AdminUserRepository::upgradePassword()).
        $this->addSql('INSERT INTO admin_user (username, password) VALUES (?, ?)', [$username, password_hash($password, PASSWORD_DEFAULT)]);
    }

    private function env(string $name): string
    {
        $value = $_SERVER[$name] ?? $_ENV[$name] ?? getenv($name);

        return is_string($value) ? trim($value) : '';
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('DROP TABLE admin_user');
    }
}
