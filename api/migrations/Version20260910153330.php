<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20260910153330 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Rename onepiece_card.unique_id to print_id: it is only unique per set, not globally.';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('DROP INDEX uniq_onepiece_card_set_unique_id ON onepiece_card');
        $this->addSql('ALTER TABLE onepiece_card CHANGE unique_id print_id VARCHAR(20) NOT NULL');
        $this->addSql('CREATE UNIQUE INDEX uniq_onepiece_card_set_print_id ON onepiece_card (set_id, print_id)');
    }

    public function down(Schema $schema): void
    {
        $this->addSql('DROP INDEX uniq_onepiece_card_set_print_id ON onepiece_card');
        $this->addSql('ALTER TABLE onepiece_card CHANGE print_id unique_id VARCHAR(20) NOT NULL');
        $this->addSql('CREATE UNIQUE INDEX uniq_onepiece_card_set_unique_id ON onepiece_card (set_id, unique_id)');
    }
}
