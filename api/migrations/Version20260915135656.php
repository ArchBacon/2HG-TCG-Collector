<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20260915135656 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE dragonballfusion_card (id BINARY(16) NOT NULL, card_id VARCHAR(20) NOT NULL, lang VARCHAR(255) NOT NULL, name VARCHAR(255) NOT NULL, card_type VARCHAR(30) NOT NULL, color VARCHAR(20) DEFAULT NULL, cost INT DEFAULT NULL, specified_cost VARCHAR(10) DEFAULT NULL, power INT DEFAULT NULL, combo_power INT DEFAULT NULL, features VARCHAR(255) DEFAULT NULL, effect LONGTEXT NOT NULL, get_it VARCHAR(255) NOT NULL, rarity VARCHAR(255) DEFAULT NULL, image_uri VARCHAR(512) DEFAULT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, set_id BINARY(16) NOT NULL, INDEX IDX_D1480DF10FB0D18 (set_id), UNIQUE INDEX uniq_dragonballfusion_card_card_id (card_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE dragonballfusion_set (id BINARY(16) NOT NULL, set_id VARCHAR(20) NOT NULL, name VARCHAR(255) NOT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, UNIQUE INDEX uniq_dragonballfusion_set_set_id (set_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('ALTER TABLE dragonballfusion_card ADD CONSTRAINT FK_D1480DF10FB0D18 FOREIGN KEY (set_id) REFERENCES dragonballfusion_set (id)');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE dragonballfusion_card DROP FOREIGN KEY FK_D1480DF10FB0D18');
        $this->addSql('DROP TABLE dragonballfusion_card');
        $this->addSql('DROP TABLE dragonballfusion_set');
    }
}
