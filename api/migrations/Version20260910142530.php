<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20260910142530 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE onepiece_card (id BINARY(16) NOT NULL, card_id VARCHAR(20) NOT NULL, unique_id VARCHAR(20) NOT NULL, lang VARCHAR(255) NOT NULL, name VARCHAR(255) NOT NULL, type VARCHAR(20) NOT NULL, color VARCHAR(30) NOT NULL, cost INT DEFAULT NULL, power INT DEFAULT NULL, life INT DEFAULT NULL, counter_amount INT DEFAULT NULL, attribute VARCHAR(20) DEFAULT NULL, sub_types VARCHAR(255) DEFAULT NULL, text LONGTEXT DEFAULT NULL, rarity VARCHAR(255) NOT NULL, image_uri VARCHAR(512) DEFAULT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, set_id BINARY(16) NOT NULL, INDEX IDX_37E1077910FB0D18 (set_id), UNIQUE INDEX uniq_onepiece_card_unique_id (unique_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE onepiece_set (id BINARY(16) NOT NULL, set_id VARCHAR(10) NOT NULL, name VARCHAR(255) NOT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, UNIQUE INDEX uniq_onepiece_set_set_id (set_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('ALTER TABLE onepiece_card ADD CONSTRAINT FK_37E1077910FB0D18 FOREIGN KEY (set_id) REFERENCES onepiece_set (id)');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE onepiece_card DROP FOREIGN KEY FK_37E1077910FB0D18');
        $this->addSql('DROP TABLE onepiece_card');
        $this->addSql('DROP TABLE onepiece_set');
    }
}
