<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20260903190558 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE pokemon_card ADD primary_dex_id INT DEFAULT NULL');
        $this->addSql('CREATE INDEX idx_pkm_card_primary_dex_id ON pokemon_card (primary_dex_id)');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('DROP INDEX idx_pkm_card_primary_dex_id ON pokemon_card');
        $this->addSql('ALTER TABLE pokemon_card DROP primary_dex_id');
    }
}
