<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20260905142250 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Add lorcana_set and lorcana_card, backed by lorcana-api.com.';
    }

    public function up(Schema $schema): void
    {
        $this->addSql(<<<'SQL'
            CREATE TABLE lorcana_card (
              id BINARY(16) NOT NULL,
              unique_id VARCHAR(20) NOT NULL,
              card_num INT NOT NULL,
              name VARCHAR(255) NOT NULL,
              type VARCHAR(50) NOT NULL,
              color VARCHAR(60) NOT NULL,
              cost INT NOT NULL,
              inkable TINYINT NOT NULL,
              rarity VARCHAR(255) NOT NULL,
              body_text LONGTEXT DEFAULT NULL,
              flavor_text LONGTEXT DEFAULT NULL,
              classifications VARCHAR(255) DEFAULT NULL,
              abilities VARCHAR(255) DEFAULT NULL,
              strength INT DEFAULT NULL,
              willpower INT DEFAULT NULL,
              lore INT DEFAULT NULL,
              franchise VARCHAR(100) DEFAULT NULL,
              artist VARCHAR(255) DEFAULT NULL,
              date_modified DATETIME DEFAULT NULL,
              image_uri VARCHAR(512) DEFAULT NULL,
              created_at DATETIME NOT NULL,
              updated_at DATETIME NOT NULL,
              set_id BINARY(16) NOT NULL,
              INDEX IDX_8B80396B10FB0D18 (set_id),
              UNIQUE INDEX uniq_lorcana_card_unique_id (unique_id),
              PRIMARY KEY (id)
            ) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`
        SQL);
        $this->addSql(<<<'SQL'
            CREATE TABLE lorcana_set (
              id BINARY(16) NOT NULL,
              set_id VARCHAR(10) NOT NULL,
              set_num INT NOT NULL,
              name VARCHAR(255) NOT NULL,
              released_at DATE NOT NULL,
              card_count INT NOT NULL,
              created_at DATETIME NOT NULL,
              updated_at DATETIME NOT NULL,
              UNIQUE INDEX uniq_lorcana_set_set_id (set_id),
              PRIMARY KEY (id)
            ) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`
        SQL);
        $this->addSql(<<<'SQL'
            ALTER TABLE
              lorcana_card
            ADD
              CONSTRAINT FK_8B80396B10FB0D18 FOREIGN KEY (set_id) REFERENCES lorcana_set (id)
        SQL);
    }

    public function down(Schema $schema): void
    {
        $this->addSql('ALTER TABLE lorcana_card DROP FOREIGN KEY FK_8B80396B10FB0D18');
        $this->addSql('DROP TABLE lorcana_card');
        $this->addSql('DROP TABLE lorcana_set');
    }
}
