<?php declare(strict_types=1);

namespace App\Contract;

use Throwable;

interface ImageJobHandlerInterface
{
    /**
     * Downloads and converts the image for a single card, writing every output size before
     * returning. Deliberately one card at a time rather than batched: a worker processes one
     * claimed job fully (download -> convert -> write) before starting the next, so no image
     * is held in memory waiting on a sibling's slower download.
     *
     * @throws Throwable on any failure; the caller marks the job failed with the message
     */
    public function process(string $cardId): void;
}
