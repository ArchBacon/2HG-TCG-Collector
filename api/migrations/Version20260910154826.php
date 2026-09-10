<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20260910154826 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Widen onepiece_card uniqueness to (set_id, print_id, image_uri): optcgapi sometimes reuses print_id within the same set for a genuinely different print.';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('DROP INDEX uniq_onepiece_card_set_print_id ON onepiece_card');
        $this->addSql(<<<'SQL'
            CREATE UNIQUE INDEX uniq_onepiece_card_set_print_image ON onepiece_card (set_id, print_id, image_uri)
        SQL);
    }

    public function down(Schema $schema): void
    {
        $this->addSql('DROP INDEX uniq_onepiece_card_set_print_image ON onepiece_card');
        $this->addSql('CREATE UNIQUE INDEX uniq_onepiece_card_set_print_id ON onepiece_card (set_id, print_id)');
    }
}
