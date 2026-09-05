<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20260903194256 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('DROP INDEX uniq_pkm_set_tcgdex_id ON pokemon_set');
        $this->addSql('ALTER TABLE pokemon_set ADD lang VARCHAR(255) NOT NULL');
        $this->addSql('CREATE UNIQUE INDEX uniq_pkm_set_tcgdex_id_lang ON pokemon_set (tcgdex_id, lang)');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('DROP INDEX uniq_pkm_set_tcgdex_id_lang ON pokemon_set');
        $this->addSql('ALTER TABLE pokemon_set DROP lang');
        $this->addSql('CREATE UNIQUE INDEX uniq_pkm_set_tcgdex_id ON pokemon_set (tcgdex_id)');
    }
}
