<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Wishlist notifications: device_token, wishlist_notice, wishlist_push.
 */
final class Version20261102120806 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Wishlist notifications: device tokens, notices and pushes';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE device_token (id BIGINT AUTO_INCREMENT NOT NULL, token VARCHAR(255) NOT NULL, platform VARCHAR(10) DEFAULT NULL, wishlist_in_store TINYINT NOT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, user_id BINARY(16) NOT NULL, INDEX IDX_99B2415CA76ED395 (user_id), UNIQUE INDEX uniq_device_token_token (token), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE wishlist_notice (id BIGINT AUTO_INCREMENT NOT NULL, game VARCHAR(20) NOT NULL, card_id BINARY(16) NOT NULL, notice_day DATE NOT NULL, created_at DATETIME NOT NULL, user_id BINARY(16) NOT NULL, push_id BIGINT DEFAULT NULL, INDEX IDX_FB3F9A84A76ED395 (user_id), INDEX idx_wishlist_notice_push (push_id), UNIQUE INDEX uniq_wishlist_notice_user_card_day (user_id, game, card_id, notice_day), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE wishlist_push (id BIGINT AUTO_INCREMENT NOT NULL, title VARCHAR(255) NOT NULL, body VARCHAR(1000) NOT NULL, cards INT NOT NULL, created_at DATETIME NOT NULL, sent_at DATETIME DEFAULT NULL, failed_at DATETIME DEFAULT NULL, attempts INT NOT NULL, last_error VARCHAR(255) DEFAULT NULL, user_id BINARY(16) NOT NULL, INDEX IDX_2405C792A76ED395 (user_id), INDEX idx_wishlist_push_sent_failed (sent_at, failed_at), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('ALTER TABLE device_token ADD CONSTRAINT FK_99B2415CA76ED395 FOREIGN KEY (user_id) REFERENCES app_user (id) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE wishlist_notice ADD CONSTRAINT FK_FB3F9A84A76ED395 FOREIGN KEY (user_id) REFERENCES app_user (id) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE wishlist_notice ADD CONSTRAINT FK_FB3F9A84F30BCAF6 FOREIGN KEY (push_id) REFERENCES wishlist_push (id) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE wishlist_push ADD CONSTRAINT FK_2405C792A76ED395 FOREIGN KEY (user_id) REFERENCES app_user (id) ON DELETE CASCADE');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE device_token DROP FOREIGN KEY FK_99B2415CA76ED395');
        $this->addSql('ALTER TABLE wishlist_notice DROP FOREIGN KEY FK_FB3F9A84A76ED395');
        $this->addSql('ALTER TABLE wishlist_notice DROP FOREIGN KEY FK_FB3F9A84F30BCAF6');
        $this->addSql('ALTER TABLE wishlist_push DROP FOREIGN KEY FK_2405C792A76ED395');
        $this->addSql('DROP TABLE device_token');
        $this->addSql('DROP TABLE wishlist_notice');
        $this->addSql('DROP TABLE wishlist_push');
    }
}
