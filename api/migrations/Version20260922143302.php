<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20260922143302 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE image_job_queue (id BIGINT AUTO_INCREMENT NOT NULL, game VARCHAR(20) NOT NULL, card_id BINARY(16) NOT NULL, status VARCHAR(20) NOT NULL, attempts INT DEFAULT 0 NOT NULL, image_uri VARCHAR(255) DEFAULT NULL, last_error LONGTEXT DEFAULT NULL, claimed_by VARCHAR(64) DEFAULT NULL, claimed_at DATETIME DEFAULT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, INDEX idx_image_job_queue_game_status_id (game, status, id), UNIQUE INDEX uniq_image_job_queue_game_card (game, card_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE product_listing (id BIGINT AUTO_INCREMENT NOT NULL, game VARCHAR(20) NOT NULL, card_id BINARY(16) NOT NULL, finish VARCHAR(20) NOT NULL, product_id VARCHAR(64) NOT NULL, stock INT NOT NULL, price DOUBLE PRECISION NOT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, UNIQUE INDEX uniq_card_listing_game_card_finish (game, card_id, finish), UNIQUE INDEX uniq_card_listing_game_product (game, product_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE product_unmatched (id BIGINT AUTO_INCREMENT NOT NULL, game VARCHAR(20) NOT NULL, product_id VARCHAR(64) NOT NULL, name VARCHAR(255) NOT NULL, payload JSON DEFAULT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, UNIQUE INDEX uniq_unmatched_product_game_product (game, product_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE tcg_card_mtg (id BINARY(16) NOT NULL, name VARCHAR(255) NOT NULL, lang VARCHAR(255) NOT NULL, number VARCHAR(20) NOT NULL, rarity VARCHAR(60) DEFAULT NULL, artist VARCHAR(255) DEFAULT NULL, type_line VARCHAR(255) NOT NULL, faces JSON NOT NULL, face_index SMALLINT NOT NULL, oracle_text LONGTEXT DEFAULT NULL, flavor_text LONGTEXT DEFAULT NULL, variants JSON NOT NULL, related JSON NOT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, details_scryfall_id VARCHAR(36) NOT NULL, details_layout VARCHAR(18) NOT NULL, details_mana_cost VARCHAR(255) DEFAULT NULL, details_cmc DOUBLE PRECISION DEFAULT NULL, details_colors JSON NOT NULL, details_power VARCHAR(20) DEFAULT NULL, details_toughness VARCHAR(20) DEFAULT NULL, details_loyalty VARCHAR(20) DEFAULT NULL, details_legalities JSON NOT NULL, details_finishes JSON NOT NULL, details_oversized TINYINT NOT NULL, details_promo TINYINT NOT NULL, details_frame VARCHAR(6) NOT NULL, set_id BINARY(16) NOT NULL, INDEX IDX_19668FB310FB0D18 (set_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE tcg_set_mtg (id BINARY(16) NOT NULL, code VARCHAR(20) NOT NULL, name VARCHAR(255) NOT NULL, type VARCHAR(255) DEFAULT NULL, block VARCHAR(20) DEFAULT NULL, card_count INT DEFAULT NULL, released_at DATE DEFAULT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, UNIQUE INDEX uniq_mtg_set_code (code), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('ALTER TABLE tcg_card_mtg ADD CONSTRAINT FK_19668FB310FB0D18 FOREIGN KEY (set_id) REFERENCES tcg_set_mtg (id)');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE tcg_card_mtg DROP FOREIGN KEY FK_19668FB310FB0D18');
        $this->addSql('DROP TABLE image_job_queue');
        $this->addSql('DROP TABLE product_listing');
        $this->addSql('DROP TABLE product_unmatched');
        $this->addSql('DROP TABLE tcg_card_mtg');
        $this->addSql('DROP TABLE tcg_set_mtg');
    }
}
