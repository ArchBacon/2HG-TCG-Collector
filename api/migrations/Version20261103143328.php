<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20261103143328 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Card market prices per source and finish, from the card data';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE card_price (id BIGINT AUTO_INCREMENT NOT NULL, game VARCHAR(20) NOT NULL, card_id BINARY(16) NOT NULL, source VARCHAR(20) NOT NULL, finish VARCHAR(20) NOT NULL, currency VARCHAR(3) NOT NULL, price NUMERIC(10, 2) NOT NULL, updated_at DATETIME NOT NULL, synced_at DATETIME NOT NULL, UNIQUE INDEX uniq_card_price_card_source_finish (card_id, source, finish), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('DROP TABLE card_price');
    }
}
