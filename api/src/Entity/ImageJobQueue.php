<?php declare(strict_types=1);

/*
 * ✦ ── AI-GENERATED CODE ────────────────────────────────────────────── ✦
 *   This was written by an AI assistant, not by hand. Beep boop.
 * ✦ ─────────────────────────────────────────────────────────────────── ✦
 */

namespace App\Entity;

use App\Enum\ImageJobStatus;
use App\Repository\ImageJobQueueRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Uid\Uuid;

/**
 * One row per (game, card) image that needs downloading/converting. Deliberately not
 * game-specific and not FK-linked to any game's card table: {@see self::$cardId} is a loose
 * reference, resolved per {@see self::$game} by that game's tagged {@see \App\Service\ImageJobHandler}.
 *
 * Rows are claimed and mutated almost entirely through raw SQL in {@see ImageJobQueueRepository}
 * rather than the ORM's unit of work — this table is worked by many concurrent worker
 * processes, and per-row hydration/flush overhead matters at hundreds of thousands of rows.
 */
#[ORM\Entity(repositoryClass: ImageJobQueueRepository::class)]
#[ORM\Table(name: 'image_job_queue')]
#[ORM\UniqueConstraint(name: 'uniq_image_job_queue_game_card', columns: ['game', 'card_id'])]
#[ORM\Index(name: 'idx_image_job_queue_game_status_id', columns: ['game', 'status', 'id'])]
class ImageJobQueue
{
    #[ORM\Id]
    #[ORM\Column(type: 'bigint', unique: true)]
    #[ORM\GeneratedValue(strategy: 'AUTO')]
    public private(set) int $id;

    #[ORM\Column(type: 'string', length: 20)]
    public string $game {
        get => $this->game;
        set => $this->game = $value;
    }

    #[ORM\Column(type: 'uuid')]
    public Uuid $cardId {
        get => $this->cardId;
        set => $this->cardId = $value;
    }

    #[ORM\Column(type: 'string', length: 20, enumType: ImageJobStatus::class)]
    public ImageJobStatus $status {
        get => $this->status;
        set => $this->status = $value;
    }

    #[ORM\Column(type: 'integer', options: ['default' => 0])]
    public int $attempts = 0 {
        get => $this->attempts;
        set => $this->attempts = $value;
    }

    #[ORM\Column(type: 'text', nullable: true)]
    public ?string $lastError = null {
        get => $this->lastError;
        set => $this->lastError = $value;
    }

    #[ORM\Column(type: 'string', length: 64, nullable: true)]
    public ?string $claimedBy = null {
        get => $this->claimedBy;
        set => $this->claimedBy = $value;
    }

    #[ORM\Column(nullable: true)]
    public ?\DateTimeImmutable $claimedAt = null {
        get => $this->claimedAt;
        set => $this->claimedAt = $value;
    }

    #[ORM\Column]
    public private(set) \DateTimeImmutable $createdAt;

    #[ORM\Column]
    public private(set) \DateTimeImmutable $updatedAt;

    public function __construct(string $game, Uuid $cardId)
    {
        $this->game = $game;
        $this->cardId = $cardId;
        $this->status = ImageJobStatus::Pending;
        $this->createdAt = new \DateTimeImmutable();
        $this->updatedAt = $this->createdAt;
    }
}
