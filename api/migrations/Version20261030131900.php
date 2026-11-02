<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20261030131900 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE admin_user (id INT AUTO_INCREMENT NOT NULL, username VARCHAR(180) NOT NULL, password VARCHAR(255) NOT NULL, UNIQUE INDEX UNIQ_AD8A54A9F85E0677 (username), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE app_setting (name VARCHAR(64) NOT NULL, value LONGTEXT NOT NULL, updated_at DATETIME NOT NULL, PRIMARY KEY (name)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE app_user (id BINARY(16) NOT NULL, secret_hash VARCHAR(255) NOT NULL, synced_secret_hashes JSON NOT NULL, created_at DATETIME NOT NULL, last_seen_at DATETIME NOT NULL, PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE applied_change (id BINARY(16) NOT NULL, applied_at DATETIME NOT NULL, user_id BINARY(16) NOT NULL, INDEX IDX_4FB66DDAA76ED395 (user_id), INDEX idx_applied_change_applied_at (applied_at), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE card_list (id BINARY(16) NOT NULL, type VARCHAR(20) NOT NULL, name VARCHAR(100) NOT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, user_id BINARY(16) NOT NULL, INDEX IDX_A8FBFABAA76ED395 (user_id), INDEX idx_card_list_user_type (user_id, type), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE card_list_entry (id BIGINT AUTO_INCREMENT NOT NULL, game VARCHAR(20) NOT NULL, card_id BINARY(16) NOT NULL, finish VARCHAR(20) NOT NULL, quantity INT UNSIGNED NOT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, list_id BINARY(16) NOT NULL, INDEX IDX_9EC0947D3DAE168B (list_id), INDEX idx_card_list_entry_game_card (game, card_id), UNIQUE INDEX uniq_card_list_entry_list_card_finish (list_id, game, card_id, finish), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE image_job_queue (id BIGINT AUTO_INCREMENT NOT NULL, game VARCHAR(20) NOT NULL, card_id BINARY(16) NOT NULL, status VARCHAR(20) NOT NULL, attempts INT DEFAULT 0 NOT NULL, image_uri VARCHAR(255) DEFAULT NULL, last_error LONGTEXT DEFAULT NULL, claimed_by VARCHAR(64) DEFAULT NULL, claimed_at DATETIME DEFAULT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, INDEX idx_image_job_queue_game_status_id (game, status, id), UNIQUE INDEX uniq_image_job_queue_game_card (game, card_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE product_listing (id BIGINT AUTO_INCREMENT NOT NULL, game VARCHAR(20) NOT NULL, card_id BINARY(16) NOT NULL, finish VARCHAR(20) NOT NULL, product_id VARCHAR(64) NOT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, UNIQUE INDEX uniq_card_listing_game_card_finish (game, card_id, finish), UNIQUE INDEX uniq_card_listing_game_product (game, product_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE product_listing_condition (id BIGINT AUTO_INCREMENT NOT NULL, variant_id VARCHAR(64) NOT NULL, condition_name VARCHAR(60) NOT NULL, stock INT NOT NULL, price DOUBLE PRECISION NOT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, listing_id BIGINT NOT NULL, INDEX IDX_B9655E50D4619D1A (listing_id), UNIQUE INDEX uniq_listing_condition_variant (listing_id, variant_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE product_unmatched (id BIGINT AUTO_INCREMENT NOT NULL, game VARCHAR(20) DEFAULT NULL, product_id VARCHAR(64) NOT NULL, name VARCHAR(255) NOT NULL, reason VARCHAR(255) DEFAULT NULL, payload JSON DEFAULT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, UNIQUE INDEX uniq_unmatched_product_product (product_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE sync_code (code VARCHAR(8) NOT NULL, created_at DATETIME NOT NULL, expires_at DATETIME NOT NULL, used_at DATETIME DEFAULT NULL, user_id BINARY(16) NOT NULL, INDEX IDX_25C39CD7A76ED395 (user_id), INDEX idx_sync_code_expires_at (expires_at), PRIMARY KEY (code)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
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
        $this->addSql('ALTER TABLE applied_change ADD CONSTRAINT FK_4FB66DDAA76ED395 FOREIGN KEY (user_id) REFERENCES app_user (id) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE card_list ADD CONSTRAINT FK_A8FBFABAA76ED395 FOREIGN KEY (user_id) REFERENCES app_user (id) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE card_list_entry ADD CONSTRAINT FK_9EC0947D3DAE168B FOREIGN KEY (list_id) REFERENCES card_list (id) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE product_listing_condition ADD CONSTRAINT FK_B9655E50D4619D1A FOREIGN KEY (listing_id) REFERENCES product_listing (id) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE sync_code ADD CONSTRAINT FK_25C39CD7A76ED395 FOREIGN KEY (user_id) REFERENCES app_user (id) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE tcg_dragonballfusion_card ADD CONSTRAINT FK_43D7A24C10FB0D18 FOREIGN KEY (set_id) REFERENCES tcg_dragonballfusion_set (id)');
        $this->addSql('ALTER TABLE tcg_lorcana_card ADD CONSTRAINT FK_8310A3F810FB0D18 FOREIGN KEY (set_id) REFERENCES tcg_lorcana_set (id)');
        $this->addSql('ALTER TABLE tcg_mtg_card ADD CONSTRAINT FK_C0547C1610FB0D18 FOREIGN KEY (set_id) REFERENCES tcg_mtg_set (id)');
        $this->addSql('ALTER TABLE tcg_onepiece_card ADD CONSTRAINT FK_5EEF551D10FB0D18 FOREIGN KEY (set_id) REFERENCES tcg_onepiece_set (id)');
        $this->addSql('ALTER TABLE tcg_pokemon_card ADD CONSTRAINT FK_222D7C0310FB0D18 FOREIGN KEY (set_id) REFERENCES tcg_pokemon_set (id)');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE applied_change DROP FOREIGN KEY FK_4FB66DDAA76ED395');
        $this->addSql('ALTER TABLE card_list DROP FOREIGN KEY FK_A8FBFABAA76ED395');
        $this->addSql('ALTER TABLE card_list_entry DROP FOREIGN KEY FK_9EC0947D3DAE168B');
        $this->addSql('ALTER TABLE product_listing_condition DROP FOREIGN KEY FK_B9655E50D4619D1A');
        $this->addSql('ALTER TABLE sync_code DROP FOREIGN KEY FK_25C39CD7A76ED395');
        $this->addSql('ALTER TABLE tcg_dragonballfusion_card DROP FOREIGN KEY FK_43D7A24C10FB0D18');
        $this->addSql('ALTER TABLE tcg_lorcana_card DROP FOREIGN KEY FK_8310A3F810FB0D18');
        $this->addSql('ALTER TABLE tcg_mtg_card DROP FOREIGN KEY FK_C0547C1610FB0D18');
        $this->addSql('ALTER TABLE tcg_onepiece_card DROP FOREIGN KEY FK_5EEF551D10FB0D18');
        $this->addSql('ALTER TABLE tcg_pokemon_card DROP FOREIGN KEY FK_222D7C0310FB0D18');
        $this->addSql('DROP TABLE admin_user');
        $this->addSql('DROP TABLE app_setting');
        $this->addSql('DROP TABLE app_user');
        $this->addSql('DROP TABLE applied_change');
        $this->addSql('DROP TABLE card_list');
        $this->addSql('DROP TABLE card_list_entry');
        $this->addSql('DROP TABLE image_job_queue');
        $this->addSql('DROP TABLE product_listing');
        $this->addSql('DROP TABLE product_listing_condition');
        $this->addSql('DROP TABLE product_unmatched');
        $this->addSql('DROP TABLE sync_code');
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
