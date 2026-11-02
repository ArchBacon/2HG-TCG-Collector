<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Admin announcements (announcement) and device_token.announcements.
 */
final class Version20261102125611 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Admin announcements, and the News and events switch per device';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE announcement (id INT AUTO_INCREMENT NOT NULL, title VARCHAR(100) NOT NULL, body VARCHAR(500) NOT NULL, games JSON NOT NULL, lists JSON NOT NULL, route VARCHAR(40) DEFAULT NULL, send_at DATETIME NOT NULL, status VARCHAR(20) NOT NULL, created_by VARCHAR(180) NOT NULL, sent_at DATETIME DEFAULT NULL, devices INT NOT NULL, failures INT NOT NULL, error VARCHAR(255) DEFAULT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, INDEX idx_announcement_status_send_at (status, send_at), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('ALTER TABLE device_token ADD announcements TINYINT DEFAULT 1 NOT NULL');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('DROP TABLE announcement');
        $this->addSql('ALTER TABLE device_token DROP announcements');
    }
}
