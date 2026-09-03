<?php

declare(strict_types=1);

namespace TcgCollector\Mtg\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Baseline schema for the MTG bundle: mtg_set, mtg_card, mtg_card_symbol.
 */
final class Version1 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Baseline schema: mtg_set, mtg_card, mtg_card_symbol';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE mtg_card (id BINARY(16) NOT NULL, scryfall_id VARCHAR(36) NOT NULL, oracle_id VARCHAR(36) DEFAULT NULL, face_index SMALLINT DEFAULT 0 NOT NULL, lang VARCHAR(255) NOT NULL, layout VARCHAR(255) NOT NULL, name VARCHAR(255) NOT NULL, printed_name VARCHAR(255) DEFAULT NULL, flavor_name VARCHAR(255) DEFAULT NULL, mana_cost VARCHAR(255) DEFAULT NULL, cmc DOUBLE PRECISION DEFAULT NULL, type_line VARCHAR(255) NOT NULL, printed_type_line VARCHAR(255) DEFAULT NULL, oracle_text LONGTEXT DEFAULT NULL, printed_text LONGTEXT DEFAULT NULL, flavor_text LONGTEXT DEFAULT NULL, colors JSON DEFAULT NULL, color_identity JSON NOT NULL, color_indicator JSON DEFAULT NULL, produced_mana JSON DEFAULT NULL, keywords JSON NOT NULL, power VARCHAR(20) DEFAULT NULL, toughness VARCHAR(20) DEFAULT NULL, loyalty VARCHAR(20) DEFAULT NULL, defense VARCHAR(20) DEFAULT NULL, life_modifier VARCHAR(20) DEFAULT NULL, hand_modifier VARCHAR(20) DEFAULT NULL, attraction_lights JSON DEFAULT NULL, legalities JSON NOT NULL, multiverse_ids JSON NOT NULL, mtgo_id INT DEFAULT NULL, mtgo_foil_id INT DEFAULT NULL, arena_id INT DEFAULT NULL, tcgplayer_id INT DEFAULT NULL, tcgplayer_etched_id INT DEFAULT NULL, cardmarket_id INT DEFAULT NULL, resource_id VARCHAR(255) DEFAULT NULL, highres_image TINYINT NOT NULL, image_status VARCHAR(255) NOT NULL, image_updated_at DATETIME DEFAULT NULL, games JSON NOT NULL, reserved TINYINT NOT NULL, game_changer TINYINT NOT NULL, foil TINYINT NOT NULL, nonfoil TINYINT NOT NULL, finishes JSON NOT NULL, oversized TINYINT NOT NULL, promo TINYINT NOT NULL, reprint TINYINT NOT NULL, variation TINYINT NOT NULL, variation_of VARCHAR(36) DEFAULT NULL, collector_number VARCHAR(20) NOT NULL, digital TINYINT NOT NULL, rarity VARCHAR(255) NOT NULL, watermark VARCHAR(255) DEFAULT NULL, card_back_id VARCHAR(36) DEFAULT NULL, artist VARCHAR(255) DEFAULT NULL, artist_ids JSON DEFAULT NULL, illustration_id VARCHAR(36) DEFAULT NULL, border_color VARCHAR(255) NOT NULL, frame VARCHAR(255) NOT NULL, frame_effects JSON DEFAULT NULL, security_stamp VARCHAR(255) DEFAULT NULL, full_art TINYINT NOT NULL, textless TINYINT NOT NULL, booster TINYINT NOT NULL, story_spotlight TINYINT NOT NULL, promo_types JSON DEFAULT NULL, content_warning TINYINT DEFAULT NULL, edhrec_rank INT DEFAULT NULL, penny_rank INT DEFAULT NULL, related_uris JSON NOT NULL, purchase_uris JSON NOT NULL, all_parts JSON DEFAULT NULL, scryfall_uri VARCHAR(512) NOT NULL, released_at DATE NOT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, image_uris_small VARCHAR(512) DEFAULT NULL, image_uris_normal VARCHAR(512) DEFAULT NULL, image_uris_large VARCHAR(512) DEFAULT NULL, image_uris_png VARCHAR(512) DEFAULT NULL, image_uris_art_crop VARCHAR(512) DEFAULT NULL, image_uris_border_crop VARCHAR(512) DEFAULT NULL, image_uris_thumb VARCHAR(512) DEFAULT NULL, image_uris_grid VARCHAR(512) DEFAULT NULL, image_uris_display VARCHAR(512) DEFAULT NULL, image_uris_art VARCHAR(512) DEFAULT NULL, image_uris_crop VARCHAR(512) DEFAULT NULL, preview_previewed_at DATE DEFAULT NULL, preview_source VARCHAR(255) DEFAULT NULL, preview_source_uri VARCHAR(512) DEFAULT NULL, prices_usd VARCHAR(20) DEFAULT NULL, prices_usd_foil VARCHAR(20) DEFAULT NULL, prices_usd_etched VARCHAR(20) DEFAULT NULL, prices_eur VARCHAR(20) DEFAULT NULL, prices_eur_foil VARCHAR(20) DEFAULT NULL, prices_tix VARCHAR(20) DEFAULT NULL, set_id BINARY(16) NOT NULL, other_face_id BINARY(16) DEFAULT NULL, INDEX IDX_AE09BE0C10FB0D18 (set_id), UNIQUE INDEX UNIQ_AE09BE0CEE95F2BC (other_face_id), INDEX idx_mtg_card_oracle_id (oracle_id), UNIQUE INDEX uniq_mtg_card_scryfall_id_face_index (scryfall_id, face_index), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE mtg_card_symbol (id BINARY(16) NOT NULL, symbol VARCHAR(20) NOT NULL, svg_uri VARCHAR(512) NOT NULL, loose_variant VARCHAR(20) DEFAULT NULL, english VARCHAR(255) NOT NULL, transposable TINYINT NOT NULL, represents_mana TINYINT NOT NULL, appears_in_mana_costs TINYINT NOT NULL, mana_value DOUBLE PRECISION DEFAULT NULL, hybrid TINYINT NOT NULL, phyrexian TINYINT NOT NULL, funny TINYINT NOT NULL, colors JSON NOT NULL, gatherer_alternates JSON DEFAULT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, UNIQUE INDEX uniq_mtg_card_symbol_symbol (symbol), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE mtg_set (id BINARY(16) NOT NULL, scryfall_id VARCHAR(36) NOT NULL, code VARCHAR(20) NOT NULL, mtgo_code VARCHAR(20) DEFAULT NULL, arena_code VARCHAR(20) DEFAULT NULL, tcgplayer_id INT DEFAULT NULL, name VARCHAR(255) NOT NULL, set_type VARCHAR(255) NOT NULL, released_at DATE DEFAULT NULL, card_count INT NOT NULL, printed_size INT DEFAULT NULL, digital TINYINT NOT NULL, foil_only TINYINT NOT NULL, nonfoil_only TINYINT NOT NULL, block_code VARCHAR(20) DEFAULT NULL, block VARCHAR(255) DEFAULT NULL, parent_set_code VARCHAR(20) DEFAULT NULL, icon_svg_uri VARCHAR(512) DEFAULT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, UNIQUE INDEX uniq_mtg_set_scryfall_id (scryfall_id), UNIQUE INDEX uniq_mtg_set_code (code), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('ALTER TABLE mtg_card ADD CONSTRAINT FK_AE09BE0C10FB0D18 FOREIGN KEY (set_id) REFERENCES mtg_set (id)');
        $this->addSql('ALTER TABLE mtg_card ADD CONSTRAINT FK_AE09BE0CEE95F2BC FOREIGN KEY (other_face_id) REFERENCES mtg_card (id)');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE mtg_card DROP FOREIGN KEY FK_AE09BE0C10FB0D18');
        $this->addSql('ALTER TABLE mtg_card DROP FOREIGN KEY FK_AE09BE0CEE95F2BC');
        $this->addSql('DROP TABLE mtg_card');
        $this->addSql('DROP TABLE mtg_card_symbol');
        $this->addSql('DROP TABLE mtg_set');
    }
}
