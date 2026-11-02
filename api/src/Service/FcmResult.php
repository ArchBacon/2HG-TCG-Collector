<?php declare(strict_types=1);

namespace App\Service;

/**
 * How a send with {@see FcmClient} went: sent, the device token is no longer valid (delete it), or
 * failed otherwise (try again later).
 */
final readonly class FcmResult
{
    private function __construct(
        public bool $sent,
        public bool $invalidToken,
        public ?string $error,
    ) {}

    public static function sent(): self
    {
        return new self(true, false, null);
    }

    public static function invalidToken(string $error): self
    {
        return new self(false, true, $error);
    }

    public static function failed(string $error): self
    {
        return new self(false, false, $error);
    }
}
