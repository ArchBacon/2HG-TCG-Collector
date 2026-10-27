<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

final class Version20261021090000 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Secrets of the devices that joined a user through a sync code.';
    }

    public function up(Schema $schema): void
    {
        // Nullable first, so existing users can be given an empty list before it's required
        $this->addSql('ALTER TABLE app_user ADD synced_secret_hashes JSON DEFAULT NULL');
        $this->addSql("UPDATE app_user SET synced_secret_hashes = '[]'");
        $this->addSql('ALTER TABLE app_user MODIFY synced_secret_hashes JSON NOT NULL');
    }

    public function down(Schema $schema): void
    {
        $this->addSql('ALTER TABLE app_user DROP synced_secret_hashes');
    }
}
