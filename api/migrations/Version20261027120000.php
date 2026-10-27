<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

final class Version20261027120000 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Shop stock per condition; unmatched products with a reason, and without a game while it is unknown.';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('CREATE TABLE product_listing_condition (id BIGINT AUTO_INCREMENT NOT NULL, variant_id VARCHAR(64) NOT NULL, condition_name VARCHAR(60) NOT NULL, stock INT NOT NULL, price DOUBLE PRECISION NOT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, listing_id BIGINT NOT NULL, INDEX IDX_B9655E50D4619D1A (listing_id), UNIQUE INDEX uniq_listing_condition_variant (listing_id, variant_id), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('ALTER TABLE product_listing_condition ADD CONSTRAINT FK_B9655E50D4619D1A FOREIGN KEY (listing_id) REFERENCES product_listing (id) ON DELETE CASCADE');

        // Listings so far had one stock and price, sold as near mint; keep them as that condition
        // until the shop's next update replaces it with its own conditions
        $this->addSql("INSERT INTO product_listing_condition (listing_id, variant_id, condition_name, stock, price, created_at, updated_at)
                       SELECT id, product_id, 'Near Mint', stock, price, created_at, updated_at FROM product_listing");
        $this->addSql('ALTER TABLE product_listing DROP stock, DROP price');

        $this->addSql('DROP INDEX uniq_unmatched_product_game_product ON product_unmatched');
        $this->addSql('ALTER TABLE product_unmatched ADD reason VARCHAR(255) DEFAULT NULL, CHANGE game game VARCHAR(20) DEFAULT NULL');
        $this->addSql('CREATE UNIQUE INDEX uniq_unmatched_product_product ON product_unmatched (product_id)');
    }

    public function down(Schema $schema): void
    {
        $this->addSql('DROP INDEX uniq_unmatched_product_product ON product_unmatched');
        $this->addSql("UPDATE product_unmatched SET game = '' WHERE game IS NULL");
        $this->addSql('ALTER TABLE product_unmatched DROP reason, CHANGE game game VARCHAR(20) NOT NULL');
        $this->addSql('CREATE UNIQUE INDEX uniq_unmatched_product_game_product ON product_unmatched (game, product_id)');

        $this->addSql('ALTER TABLE product_listing ADD stock INT NOT NULL DEFAULT 0, ADD price DOUBLE PRECISION NOT NULL DEFAULT 0');
        // Back to one stock and price: the total stock, at the lowest price in stock
        $this->addSql('UPDATE product_listing l SET
                           stock = (SELECT COALESCE(SUM(k.stock), 0) FROM product_listing_condition k WHERE k.listing_id = l.id),
                           price = (SELECT COALESCE(MIN(k.price), 0) FROM product_listing_condition k WHERE k.listing_id = l.id AND k.stock > 0)');
        $this->addSql('ALTER TABLE product_listing ALTER stock DROP DEFAULT, ALTER price DROP DEFAULT');
        $this->addSql('DROP TABLE product_listing_condition');
    }
}
