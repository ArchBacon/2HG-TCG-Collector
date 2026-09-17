<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20260916160028 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE image_job_queue ADD image_uri VARCHAR(255) DEFAULT NULL');
        $this->addSql('ALTER TABLE mtg_card DROP FOREIGN KEY `FK_AE09BE0CEE95F2BC`');
        $this->addSql('DROP INDEX uniq_mtg_card_scryfall_id_face_index ON mtg_card');
        $this->addSql('DROP INDEX idx_mtg_card_oracle_id ON mtg_card');
        $this->addSql('DROP INDEX UNIQ_AE09BE0CEE95F2BC ON mtg_card');
        $this->addSql('ALTER TABLE mtg_card ADD faces JSON NOT NULL, ADD details_layout VARCHAR(18) NOT NULL, ADD details_mana_cost VARCHAR(255) DEFAULT NULL, ADD details_colors JSON NOT NULL, ADD details_power VARCHAR(20) DEFAULT NULL, ADD details_toughness VARCHAR(20) DEFAULT NULL, ADD details_loyalty VARCHAR(20) DEFAULT NULL, ADD details_legalities JSON NOT NULL, ADD details_finishes JSON NOT NULL, ADD details_oversized TINYINT NOT NULL, ADD details_promo TINYINT NOT NULL, ADD details_frame VARCHAR(6) NOT NULL, DROP oracle_id, DROP face_index, DROP layout, DROP printed_name, DROP flavor_name, DROP mana_cost, DROP printed_type_line, DROP printed_text, DROP flavor_text, DROP colors, DROP color_identity, DROP color_indicator, DROP produced_mana, DROP keywords, DROP power, DROP toughness, DROP loyalty, DROP defense, DROP life_modifier, DROP hand_modifier, DROP attraction_lights, DROP legalities, DROP multiverse_ids, DROP mtgo_id, DROP mtgo_foil_id, DROP arena_id, DROP tcgplayer_id, DROP tcgplayer_etched_id, DROP cardmarket_id, DROP resource_id, DROP highres_image, DROP image_status, DROP image_updated_at, DROP games, DROP reserved, DROP game_changer, DROP foil, DROP nonfoil, DROP finishes, DROP oversized, DROP promo, DROP reprint, DROP variation, DROP variation_of, DROP digital, DROP watermark, DROP card_back_id, DROP artist_ids, DROP illustration_id, DROP border_color, DROP frame, DROP frame_effects, DROP security_stamp, DROP full_art, DROP textless, DROP booster, DROP story_spotlight, DROP promo_types, DROP content_warning, DROP edhrec_rank, DROP penny_rank, DROP related_uris, DROP purchase_uris, DROP all_parts, DROP scryfall_uri, DROP released_at, DROP image_uris_small, DROP image_uris_normal, DROP image_uris_large, DROP image_uris_png, DROP image_uris_art_crop, DROP image_uris_border_crop, DROP image_uris_thumb, DROP image_uris_grid, DROP image_uris_display, DROP image_uris_art, DROP image_uris_crop, DROP preview_previewed_at, DROP preview_source, DROP preview_source_uri, DROP prices_usd, DROP prices_usd_foil, DROP prices_usd_etched, DROP prices_eur, DROP prices_eur_foil, DROP prices_tix, DROP other_face_id, CHANGE rarity rarity VARCHAR(60) DEFAULT NULL, CHANGE collector_number number VARCHAR(20) NOT NULL, CHANGE scryfall_id details_scryfall_id VARCHAR(36) NOT NULL, CHANGE cmc details_cmc DOUBLE PRECISION DEFAULT NULL');
        $this->addSql('DROP INDEX uniq_mtg_set_scryfall_id ON mtg_set');
        $this->addSql('ALTER TABLE mtg_set ADD type VARCHAR(255) DEFAULT NULL, DROP scryfall_id, DROP mtgo_code, DROP arena_code, DROP tcgplayer_id, DROP set_type, DROP printed_size, DROP digital, DROP foil_only, DROP nonfoil_only, DROP block_code, DROP parent_set_code, DROP icon_svg_uri, CHANGE card_count card_count INT DEFAULT NULL, CHANGE block block VARCHAR(20) DEFAULT NULL');
        $this->addSql('ALTER TABLE pokemon_card CHANGE rarity rarity VARCHAR(100) DEFAULT NULL');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE image_job_queue DROP image_uri');
        $this->addSql('ALTER TABLE mtg_card ADD oracle_id VARCHAR(36) DEFAULT NULL, ADD face_index SMALLINT DEFAULT 0 NOT NULL, ADD layout VARCHAR(255) NOT NULL, ADD flavor_name VARCHAR(255) DEFAULT NULL, ADD mana_cost VARCHAR(255) DEFAULT NULL, ADD printed_type_line VARCHAR(255) DEFAULT NULL, ADD printed_text LONGTEXT DEFAULT NULL, ADD flavor_text LONGTEXT DEFAULT NULL, ADD colors JSON DEFAULT NULL, ADD color_identity JSON NOT NULL, ADD color_indicator JSON DEFAULT NULL, ADD produced_mana JSON DEFAULT NULL, ADD keywords JSON NOT NULL, ADD power VARCHAR(20) DEFAULT NULL, ADD toughness VARCHAR(20) DEFAULT NULL, ADD loyalty VARCHAR(20) DEFAULT NULL, ADD defense VARCHAR(20) DEFAULT NULL, ADD life_modifier VARCHAR(20) DEFAULT NULL, ADD hand_modifier VARCHAR(20) DEFAULT NULL, ADD attraction_lights JSON DEFAULT NULL, ADD legalities JSON NOT NULL, ADD multiverse_ids JSON NOT NULL, ADD mtgo_id INT DEFAULT NULL, ADD mtgo_foil_id INT DEFAULT NULL, ADD arena_id INT DEFAULT NULL, ADD tcgplayer_id INT DEFAULT NULL, ADD tcgplayer_etched_id INT DEFAULT NULL, ADD cardmarket_id INT DEFAULT NULL, ADD resource_id VARCHAR(255) DEFAULT NULL, ADD highres_image TINYINT NOT NULL, ADD image_status VARCHAR(255) NOT NULL, ADD image_updated_at DATETIME DEFAULT NULL, ADD games JSON NOT NULL, ADD reserved TINYINT NOT NULL, ADD game_changer TINYINT NOT NULL, ADD foil TINYINT NOT NULL, ADD nonfoil TINYINT NOT NULL, ADD finishes JSON NOT NULL, ADD oversized TINYINT NOT NULL, ADD promo TINYINT NOT NULL, ADD reprint TINYINT NOT NULL, ADD variation TINYINT NOT NULL, ADD variation_of VARCHAR(36) DEFAULT NULL, ADD digital TINYINT NOT NULL, ADD watermark VARCHAR(255) DEFAULT NULL, ADD card_back_id VARCHAR(36) DEFAULT NULL, ADD artist_ids JSON DEFAULT NULL, ADD illustration_id VARCHAR(36) DEFAULT NULL, ADD border_color VARCHAR(255) NOT NULL, ADD frame VARCHAR(255) NOT NULL, ADD frame_effects JSON DEFAULT NULL, ADD security_stamp VARCHAR(255) DEFAULT NULL, ADD full_art TINYINT NOT NULL, ADD textless TINYINT NOT NULL, ADD booster TINYINT NOT NULL, ADD story_spotlight TINYINT NOT NULL, ADD promo_types JSON DEFAULT NULL, ADD content_warning TINYINT DEFAULT NULL, ADD edhrec_rank INT DEFAULT NULL, ADD penny_rank INT DEFAULT NULL, ADD related_uris JSON NOT NULL, ADD purchase_uris JSON NOT NULL, ADD all_parts JSON DEFAULT NULL, ADD scryfall_uri VARCHAR(512) NOT NULL, ADD released_at DATE NOT NULL, ADD image_uris_small VARCHAR(512) DEFAULT NULL, ADD image_uris_normal VARCHAR(512) DEFAULT NULL, ADD image_uris_large VARCHAR(512) DEFAULT NULL, ADD image_uris_png VARCHAR(512) DEFAULT NULL, ADD image_uris_art_crop VARCHAR(512) DEFAULT NULL, ADD image_uris_border_crop VARCHAR(512) DEFAULT NULL, ADD image_uris_thumb VARCHAR(512) DEFAULT NULL, ADD image_uris_grid VARCHAR(512) DEFAULT NULL, ADD image_uris_display VARCHAR(512) DEFAULT NULL, ADD image_uris_art VARCHAR(512) DEFAULT NULL, ADD image_uris_crop VARCHAR(512) DEFAULT NULL, ADD preview_previewed_at DATE DEFAULT NULL, ADD preview_source VARCHAR(255) DEFAULT NULL, ADD preview_source_uri VARCHAR(512) DEFAULT NULL, ADD prices_usd VARCHAR(20) DEFAULT NULL, ADD prices_usd_foil VARCHAR(20) DEFAULT NULL, ADD prices_usd_etched VARCHAR(20) DEFAULT NULL, ADD prices_eur VARCHAR(20) DEFAULT NULL, ADD prices_eur_foil VARCHAR(20) DEFAULT NULL, ADD prices_tix VARCHAR(20) DEFAULT NULL, ADD other_face_id BINARY(16) DEFAULT NULL, DROP faces, DROP details_layout, DROP details_colors, DROP details_power, DROP details_toughness, DROP details_loyalty, DROP details_legalities, DROP details_finishes, DROP details_oversized, DROP details_promo, DROP details_frame, CHANGE rarity rarity VARCHAR(255) NOT NULL, CHANGE details_scryfall_id scryfall_id VARCHAR(36) NOT NULL, CHANGE details_mana_cost printed_name VARCHAR(255) DEFAULT NULL, CHANGE details_cmc cmc DOUBLE PRECISION DEFAULT NULL, CHANGE number collector_number VARCHAR(20) NOT NULL');
        $this->addSql('ALTER TABLE mtg_card ADD CONSTRAINT `FK_AE09BE0CEE95F2BC` FOREIGN KEY (other_face_id) REFERENCES mtg_card (id)');
        $this->addSql('CREATE UNIQUE INDEX uniq_mtg_card_scryfall_id_face_index ON mtg_card (scryfall_id, face_index)');
        $this->addSql('CREATE INDEX idx_mtg_card_oracle_id ON mtg_card (oracle_id)');
        $this->addSql('CREATE UNIQUE INDEX UNIQ_AE09BE0CEE95F2BC ON mtg_card (other_face_id)');
        $this->addSql('ALTER TABLE mtg_set ADD scryfall_id VARCHAR(36) NOT NULL, ADD mtgo_code VARCHAR(20) DEFAULT NULL, ADD arena_code VARCHAR(20) DEFAULT NULL, ADD tcgplayer_id INT DEFAULT NULL, ADD set_type VARCHAR(255) NOT NULL, ADD printed_size INT DEFAULT NULL, ADD digital TINYINT NOT NULL, ADD foil_only TINYINT NOT NULL, ADD nonfoil_only TINYINT NOT NULL, ADD block_code VARCHAR(20) DEFAULT NULL, ADD parent_set_code VARCHAR(20) DEFAULT NULL, ADD icon_svg_uri VARCHAR(512) NOT NULL, DROP type, CHANGE block block VARCHAR(255) DEFAULT NULL, CHANGE card_count card_count INT NOT NULL');
        $this->addSql('CREATE UNIQUE INDEX uniq_mtg_set_scryfall_id ON mtg_set (scryfall_id)');
        $this->addSql('ALTER TABLE pokemon_card CHANGE rarity rarity VARCHAR(100) NOT NULL');
    }
}
