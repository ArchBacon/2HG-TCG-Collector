<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20260910155200 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Widen onepiece_card.attribute to 255 chars: optcgapi has at least one row where it duplicates sub_types instead of holding a real attribute value.';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('ALTER TABLE onepiece_card CHANGE attribute attribute VARCHAR(255) DEFAULT NULL');
    }

    public function down(Schema $schema): void
    {
        $this->addSql('ALTER TABLE onepiece_card CHANGE attribute attribute VARCHAR(20) DEFAULT NULL');
    }
}
