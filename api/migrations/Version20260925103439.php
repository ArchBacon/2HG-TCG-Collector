<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20260925103439 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE app_user (id BINARY(16) NOT NULL, secret_hash VARCHAR(255) NOT NULL, created_at DATETIME NOT NULL, last_seen_at DATETIME NOT NULL, PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE applied_change (id BINARY(16) NOT NULL, applied_at DATETIME NOT NULL, user_id BINARY(16) NOT NULL, INDEX IDX_4FB66DDAA76ED395 (user_id), INDEX idx_applied_change_applied_at (applied_at), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE card_list (id BINARY(16) NOT NULL, type VARCHAR(20) NOT NULL, name VARCHAR(100) NOT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, user_id BINARY(16) NOT NULL, INDEX IDX_A8FBFABAA76ED395 (user_id), INDEX idx_card_list_user_type (user_id, type), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE card_list_entry (id BIGINT AUTO_INCREMENT NOT NULL, game VARCHAR(20) NOT NULL, card_id BINARY(16) NOT NULL, finish VARCHAR(20) NOT NULL, quantity INT UNSIGNED NOT NULL, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, list_id BINARY(16) NOT NULL, INDEX IDX_9EC0947D3DAE168B (list_id), INDEX idx_card_list_entry_game_card (game, card_id), UNIQUE INDEX uniq_card_list_entry_list_card_finish (list_id, game, card_id, finish), PRIMARY KEY (id)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('CREATE TABLE sync_code (code VARCHAR(8) NOT NULL, created_at DATETIME NOT NULL, expires_at DATETIME NOT NULL, used_at DATETIME DEFAULT NULL, user_id BINARY(16) NOT NULL, INDEX IDX_25C39CD7A76ED395 (user_id), INDEX idx_sync_code_expires_at (expires_at), PRIMARY KEY (code)) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci`');
        $this->addSql('ALTER TABLE applied_change ADD CONSTRAINT FK_4FB66DDAA76ED395 FOREIGN KEY (user_id) REFERENCES app_user (id) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE card_list ADD CONSTRAINT FK_A8FBFABAA76ED395 FOREIGN KEY (user_id) REFERENCES app_user (id) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE card_list_entry ADD CONSTRAINT FK_9EC0947D3DAE168B FOREIGN KEY (list_id) REFERENCES card_list (id) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE sync_code ADD CONSTRAINT FK_25C39CD7A76ED395 FOREIGN KEY (user_id) REFERENCES app_user (id) ON DELETE CASCADE');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE applied_change DROP FOREIGN KEY FK_4FB66DDAA76ED395');
        $this->addSql('ALTER TABLE card_list DROP FOREIGN KEY FK_A8FBFABAA76ED395');
        $this->addSql('ALTER TABLE card_list_entry DROP FOREIGN KEY FK_9EC0947D3DAE168B');
        $this->addSql('ALTER TABLE sync_code DROP FOREIGN KEY FK_25C39CD7A76ED395');
        $this->addSql('DROP TABLE app_user');
        $this->addSql('DROP TABLE applied_change');
        $this->addSql('DROP TABLE card_list');
        $this->addSql('DROP TABLE card_list_entry');
        $this->addSql('DROP TABLE sync_code');
    }
}
