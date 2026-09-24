<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20260924113549 extends AbstractMigration
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
        $this->addSql('CREATE TABLE tcg_dragonballfusion_card (id BINARY(16) NOT NULL, name VARCHAR(255) NOT NULL, lang VARCHAR(255) NOT NULL, number VARCHAR(20) NOT NULL, rarity VARCHAR(60) DEFAULT NULL, artist VARCHAR(255) DEFAULT NULL, type_line VARCHAR(255) NOT NULL, faces JSON NOT NULL, face_index SMALLINT NOT NULL, oracle_text LONGTEXT DEFAULT NULL, flavor_text LONGTEXT DEFAULT NULL, variants JSON NOT NULL, related JSON NOT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, details_color VARCHAR(20) DEFAULT NULL, details_cost INT DEFAULT NULL, details_specified_cost VARCHAR(10) DEFAULT NULL, details_power INT DEFAULT NULL, details_combo_power INT DEFAULT NULL, details_features VARCHAR(255) DEFAULT NULL, set_id BINARY(16) NOT NULL, INDEX IDX_43D7A24C10FB0D18 (set_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE tcg_dragonballfusion_set (id BINARY(16) NOT NULL, code VARCHAR(20) NOT NULL, name VARCHAR(255) NOT NULL, lang VARCHAR(4) DEFAULT NULL, type VARCHAR(255) DEFAULT NULL, block VARCHAR(20) DEFAULT NULL, card_count INT DEFAULT NULL, released_at DATE DEFAULT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, UNIQUE INDEX uniq_dragonballfusion_set_code (code), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE tcg_lorcana_card (id BINARY(16) NOT NULL, name VARCHAR(255) NOT NULL, lang VARCHAR(255) NOT NULL, number VARCHAR(20) NOT NULL, rarity VARCHAR(60) DEFAULT NULL, artist VARCHAR(255) DEFAULT NULL, type_line VARCHAR(255) NOT NULL, faces JSON NOT NULL, face_index SMALLINT NOT NULL, oracle_text LONGTEXT DEFAULT NULL, flavor_text LONGTEXT DEFAULT NULL, variants JSON NOT NULL, related JSON NOT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, details_unique_id VARCHAR(20) NOT NULL, details_color VARCHAR(60) NOT NULL, details_cost INT NOT NULL, details_inkable TINYINT NOT NULL, details_classifications VARCHAR(255) DEFAULT NULL, details_abilities VARCHAR(255) DEFAULT NULL, details_strength INT DEFAULT NULL, details_willpower INT DEFAULT NULL, details_lore INT DEFAULT NULL, details_franchise VARCHAR(100) DEFAULT NULL, set_id BINARY(16) NOT NULL, INDEX IDX_8310A3F810FB0D18 (set_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE tcg_lorcana_set (id BINARY(16) NOT NULL, code VARCHAR(20) NOT NULL, name VARCHAR(255) NOT NULL, lang VARCHAR(4) DEFAULT NULL, type VARCHAR(255) DEFAULT NULL, block VARCHAR(20) DEFAULT NULL, card_count INT DEFAULT NULL, released_at DATE DEFAULT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, UNIQUE INDEX uniq_lorcana_set_code (code), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE tcg_mtg_card (id BINARY(16) NOT NULL, name VARCHAR(255) NOT NULL, lang VARCHAR(255) NOT NULL, number VARCHAR(20) NOT NULL, rarity VARCHAR(60) DEFAULT NULL, artist VARCHAR(255) DEFAULT NULL, type_line VARCHAR(255) NOT NULL, faces JSON NOT NULL, face_index SMALLINT NOT NULL, oracle_text LONGTEXT DEFAULT NULL, flavor_text LONGTEXT DEFAULT NULL, variants JSON NOT NULL, related JSON NOT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, details_scryfall_id VARCHAR(36) NOT NULL, details_layout VARCHAR(18) NOT NULL, details_mana_cost VARCHAR(255) DEFAULT NULL, details_cmc DOUBLE PRECISION DEFAULT NULL, details_colors JSON NOT NULL, details_power VARCHAR(20) DEFAULT NULL, details_toughness VARCHAR(20) DEFAULT NULL, details_loyalty VARCHAR(20) DEFAULT NULL, details_legalities JSON NOT NULL, details_finishes JSON NOT NULL, details_oversized TINYINT NOT NULL, details_promo TINYINT NOT NULL, details_frame VARCHAR(6) NOT NULL, set_id BINARY(16) NOT NULL, INDEX IDX_C0547C1610FB0D18 (set_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE tcg_mtg_set (id BINARY(16) NOT NULL, code VARCHAR(20) NOT NULL, name VARCHAR(255) NOT NULL, lang VARCHAR(4) DEFAULT NULL, type VARCHAR(255) DEFAULT NULL, block VARCHAR(20) DEFAULT NULL, card_count INT DEFAULT NULL, released_at DATE DEFAULT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, UNIQUE INDEX uniq_mtg_set_code (code), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE tcg_onepiece_card (id BINARY(16) NOT NULL, name VARCHAR(255) NOT NULL, lang VARCHAR(255) NOT NULL, number VARCHAR(20) NOT NULL, rarity VARCHAR(60) DEFAULT NULL, artist VARCHAR(255) DEFAULT NULL, type_line VARCHAR(255) NOT NULL, faces JSON NOT NULL, face_index SMALLINT NOT NULL, oracle_text LONGTEXT DEFAULT NULL, flavor_text LONGTEXT DEFAULT NULL, variants JSON NOT NULL, related JSON NOT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, details_unique_id VARCHAR(64) NOT NULL, details_color VARCHAR(30) NOT NULL, details_cost INT DEFAULT NULL, details_power INT DEFAULT NULL, details_life INT DEFAULT NULL, details_counter_amount INT DEFAULT NULL, details_attribute VARCHAR(255) DEFAULT NULL, details_sub_types VARCHAR(255) DEFAULT NULL, set_id BINARY(16) NOT NULL, INDEX IDX_5EEF551D10FB0D18 (set_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE tcg_onepiece_set (id BINARY(16) NOT NULL, code VARCHAR(20) NOT NULL, name VARCHAR(255) NOT NULL, lang VARCHAR(4) DEFAULT NULL, type VARCHAR(255) DEFAULT NULL, block VARCHAR(20) DEFAULT NULL, card_count INT DEFAULT NULL, released_at DATE DEFAULT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, UNIQUE INDEX uniq_onepiece_set_code (code), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE tcg_pokemon_card (id BINARY(16) NOT NULL, name VARCHAR(255) NOT NULL, lang VARCHAR(255) NOT NULL, number VARCHAR(20) NOT NULL, rarity VARCHAR(60) DEFAULT NULL, artist VARCHAR(255) DEFAULT NULL, type_line VARCHAR(255) NOT NULL, faces JSON NOT NULL, face_index SMALLINT NOT NULL, oracle_text LONGTEXT DEFAULT NULL, flavor_text LONGTEXT DEFAULT NULL, variants JSON NOT NULL, related JSON NOT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, details_unique_id VARCHAR(20) NOT NULL, details_finishes JSON NOT NULL, details_regulation_mark VARCHAR(20) DEFAULT NULL, details_legalities JSON NOT NULL, details_pokemon_dex_ids JSON DEFAULT NULL, details_pokemon_primary_dex_id INT DEFAULT NULL, details_pokemon_hp INT DEFAULT NULL, details_pokemon_colors JSON NOT NULL, details_pokemon_stage VARCHAR(20) DEFAULT NULL, details_pokemon_evolve_from VARCHAR(60) DEFAULT NULL, details_pokemon_level VARCHAR(20) DEFAULT NULL, details_pokemon_suffix VARCHAR(30) DEFAULT NULL, details_pokemon_item JSON DEFAULT NULL, details_pokemon_abilities JSON NOT NULL, details_pokemon_attacks JSON NOT NULL, details_pokemon_weaknesses JSON NOT NULL, details_pokemon_resistances JSON NOT NULL, details_pokemon_retreat INT DEFAULT NULL, details_trainer_trainer_type VARCHAR(30) DEFAULT NULL, details_trainer_effect LONGTEXT DEFAULT NULL, details_energy_energy_type VARCHAR(20) DEFAULT NULL, details_energy_effect LONGTEXT DEFAULT NULL, set_id BINARY(16) NOT NULL, INDEX IDX_222D7C0310FB0D18 (set_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE tcg_pokemon_set (id BINARY(16) NOT NULL, code VARCHAR(20) NOT NULL, name VARCHAR(255) NOT NULL, lang VARCHAR(4) DEFAULT NULL, type VARCHAR(255) DEFAULT NULL, block VARCHAR(20) DEFAULT NULL, card_count INT DEFAULT NULL, released_at DATE DEFAULT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('ALTER TABLE tcg_dragonballfusion_card ADD CONSTRAINT FK_43D7A24C10FB0D18 FOREIGN KEY (set_id) REFERENCES tcg_dragonballfusion_set (id)');
        $this->addSql('ALTER TABLE tcg_lorcana_card ADD CONSTRAINT FK_8310A3F810FB0D18 FOREIGN KEY (set_id) REFERENCES tcg_lorcana_set (id)');
        $this->addSql('ALTER TABLE tcg_mtg_card ADD CONSTRAINT FK_C0547C1610FB0D18 FOREIGN KEY (set_id) REFERENCES tcg_mtg_set (id)');
        $this->addSql('ALTER TABLE tcg_onepiece_card ADD CONSTRAINT FK_5EEF551D10FB0D18 FOREIGN KEY (set_id) REFERENCES tcg_onepiece_set (id)');
        $this->addSql('ALTER TABLE tcg_pokemon_card ADD CONSTRAINT FK_222D7C0310FB0D18 FOREIGN KEY (set_id) REFERENCES tcg_pokemon_set (id)');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE tcg_dragonballfusion_card DROP FOREIGN KEY FK_43D7A24C10FB0D18');
        $this->addSql('ALTER TABLE tcg_lorcana_card DROP FOREIGN KEY FK_8310A3F810FB0D18');
        $this->addSql('ALTER TABLE tcg_mtg_card DROP FOREIGN KEY FK_C0547C1610FB0D18');
        $this->addSql('ALTER TABLE tcg_onepiece_card DROP FOREIGN KEY FK_5EEF551D10FB0D18');
        $this->addSql('ALTER TABLE tcg_pokemon_card DROP FOREIGN KEY FK_222D7C0310FB0D18');
        $this->addSql('DROP TABLE image_job_queue');
        $this->addSql('DROP TABLE product_listing');
        $this->addSql('DROP TABLE product_unmatched');
        $this->addSql('DROP TABLE tcg_dragonballfusion_card');
        $this->addSql('DROP TABLE tcg_dragonballfusion_set');
        $this->addSql('DROP TABLE tcg_lorcana_card');
        $this->addSql('DROP TABLE tcg_lorcana_set');
        $this->addSql('DROP TABLE tcg_mtg_card');
        $this->addSql('DROP TABLE tcg_mtg_set');
        $this->addSql('DROP TABLE tcg_onepiece_card');
        $this->addSql('DROP TABLE tcg_onepiece_set');
        $this->addSql('DROP TABLE tcg_pokemon_card');
        $this->addSql('DROP TABLE tcg_pokemon_set');
    }
}
