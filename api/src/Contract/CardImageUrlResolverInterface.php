<?php declare(strict_types=1);

namespace App\Contract;

use http\Exception\RuntimeException;

interface CardImageUrlResolverInterface
{
    /** @throws RuntimeException if the card no longer exists */
    public function resolve(string $cardId): ?string;
}
