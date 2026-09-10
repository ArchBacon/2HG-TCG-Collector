<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20260910152737 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Scope onepiece_card uniqueness to (set_id, unique_id): optcgapi reuses unique_id values across different sets.';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('DROP INDEX uniq_onepiece_card_unique_id ON onepiece_card');
        $this->addSql('CREATE UNIQUE INDEX uniq_onepiece_card_set_unique_id ON onepiece_card (set_id, unique_id)');
    }

    public function down(Schema $schema): void
    {
        $this->addSql('DROP INDEX uniq_onepiece_card_set_unique_id ON onepiece_card');
        $this->addSql('CREATE UNIQUE INDEX uniq_onepiece_card_unique_id ON onepiece_card (unique_id)');
    }
}
