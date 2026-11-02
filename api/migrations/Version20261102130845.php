<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * device_notification: what was sent to each device, for the app's list and unread count.
 */
final class Version20261102130845 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Received notifications per device, for the app';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE device_notification (id BIGINT AUTO_INCREMENT NOT NULL, type VARCHAR(20) NOT NULL, title VARCHAR(255) NOT NULL, body VARCHAR(1000) NOT NULL, route VARCHAR(40) DEFAULT NULL, sent_at DATETIME NOT NULL, read_at DATETIME DEFAULT NULL, device_id BIGINT NOT NULL, INDEX IDX_CD21911B94A4C7D4 (device_id), INDEX idx_device_notification_device_sent (device_id, sent_at), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('ALTER TABLE device_notification ADD CONSTRAINT FK_CD21911B94A4C7D4 FOREIGN KEY (device_id) REFERENCES device_token (id) ON DELETE CASCADE');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE device_notification DROP FOREIGN KEY FK_CD21911B94A4C7D4');
        $this->addSql('DROP TABLE device_notification');
    }
}
