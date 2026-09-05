<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20260903152759 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE pokemon_card (id BINARY(16) NOT NULL, tcgdex_id VARCHAR(40) NOT NULL, lang VARCHAR(255) NOT NULL, local_id VARCHAR(20) NOT NULL, name VARCHAR(255) NOT NULL, category VARCHAR(255) NOT NULL, rarity VARCHAR(100) NOT NULL, illustrator VARCHAR(255) DEFAULT NULL, image_uri VARCHAR(512) DEFAULT NULL, variants_detailed JSON DEFAULT NULL, dex_id JSON DEFAULT NULL, hp INT DEFAULT NULL, types JSON DEFAULT NULL, evolve_from VARCHAR(255) DEFAULT NULL, description LONGTEXT DEFAULT NULL, stage VARCHAR(30) DEFAULT NULL, suffix VARCHAR(20) DEFAULT NULL, abilities JSON DEFAULT NULL, attacks JSON DEFAULT NULL, weaknesses JSON DEFAULT NULL, resistances JSON DEFAULT NULL, retreat INT DEFAULT NULL, trainer_type VARCHAR(50) DEFAULT NULL, energy_type VARCHAR(50) DEFAULT NULL, effect LONGTEXT DEFAULT NULL, regulation_mark VARCHAR(10) DEFAULT NULL, updated DATETIME DEFAULT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, variants_normal TINYINT NOT NULL, variants_reverse TINYINT NOT NULL, variants_holo TINYINT NOT NULL, variants_first_edition TINYINT NOT NULL, variants_w_promo TINYINT NOT NULL, legal_standard TINYINT NOT NULL, legal_expanded TINYINT NOT NULL, set_id BINARY(16) NOT NULL, INDEX IDX_2ABDE69010FB0D18 (set_id), UNIQUE INDEX uniq_pkm_card_tcgdex_id_lang (tcgdex_id, lang), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE pokemon_set (id BINARY(16) NOT NULL, tcgdex_id VARCHAR(30) NOT NULL, name VARCHAR(255) NOT NULL, serie_id VARCHAR(30) NOT NULL, serie_name VARCHAR(255) NOT NULL, released_at DATE NOT NULL, logo_uri VARCHAR(512) DEFAULT NULL, symbol_uri VARCHAR(512) DEFAULT NULL, tcg_online_code VARCHAR(20) DEFAULT NULL, official_abbreviation VARCHAR(20) DEFAULT NULL, local_abbreviation VARCHAR(20) DEFAULT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, card_count_total INT NOT NULL, card_count_official INT NOT NULL, card_count_holo INT NOT NULL, card_count_reverse INT NOT NULL, card_count_normal INT NOT NULL, card_count_first_ed INT NOT NULL, legal_standard TINYINT NOT NULL, legal_expanded TINYINT NOT NULL, UNIQUE INDEX uniq_pkm_set_tcgdex_id (tcgdex_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('ALTER TABLE pokemon_card ADD CONSTRAINT FK_2ABDE69010FB0D18 FOREIGN KEY (set_id) REFERENCES pokemon_set (id)');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE pokemon_card DROP FOREIGN KEY FK_2ABDE69010FB0D18');
        $this->addSql('DROP TABLE pokemon_card');
        $this->addSql('DROP TABLE pokemon_set');
    }
}
