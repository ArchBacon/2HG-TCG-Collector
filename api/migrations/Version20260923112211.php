<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20260923112211 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE tcg_dragonballfusion_card (id BINARY(16) NOT NULL, name VARCHAR(255) NOT NULL, lang VARCHAR(255) NOT NULL, number VARCHAR(20) NOT NULL, rarity VARCHAR(60) DEFAULT NULL, artist VARCHAR(255) DEFAULT NULL, type_line VARCHAR(255) NOT NULL, faces JSON NOT NULL, face_index SMALLINT NOT NULL, oracle_text LONGTEXT DEFAULT NULL, flavor_text LONGTEXT DEFAULT NULL, variants JSON NOT NULL, related JSON NOT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, details_color VARCHAR(20) DEFAULT NULL, details_cost INT DEFAULT NULL, details_specified_cost VARCHAR(10) DEFAULT NULL, details_power INT DEFAULT NULL, details_combo_power INT DEFAULT NULL, details_features VARCHAR(255) DEFAULT NULL, set_id BINARY(16) NOT NULL, INDEX IDX_43D7A24C10FB0D18 (set_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE tcg_dragonballfusion_set (id BINARY(16) NOT NULL, code VARCHAR(20) NOT NULL, name VARCHAR(255) NOT NULL, type VARCHAR(255) DEFAULT NULL, block VARCHAR(20) DEFAULT NULL, card_count INT DEFAULT NULL, released_at DATE DEFAULT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, UNIQUE INDEX uniq_dragonballfusion_set_code (code), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('ALTER TABLE tcg_dragonballfusion_card ADD CONSTRAINT FK_43D7A24C10FB0D18 FOREIGN KEY (set_id) REFERENCES tcg_dragonballfusion_set (id)');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE tcg_dragonballfusion_card DROP FOREIGN KEY FK_43D7A24C10FB0D18');
        $this->addSql('DROP TABLE tcg_dragonballfusion_card');
        $this->addSql('DROP TABLE tcg_dragonballfusion_set');
    }
}
