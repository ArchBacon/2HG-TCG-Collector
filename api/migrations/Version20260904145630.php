<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20260904145630 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Add pokemon_set.cards_fully_imported, so a resync can skip sets that already have every card TCGdex lists.';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('ALTER TABLE pokemon_set ADD cards_fully_imported TINYINT(1) NOT NULL DEFAULT 0');
    }

    public function down(Schema $schema): void
    {
        $this->addSql('ALTER TABLE pokemon_set DROP cards_fully_imported');
    }
}
