<?php declare(strict_types=1);

namespace App\Service;

use App\Entity\Setting;
use App\Repository\SettingRepository;
use DateTimeImmutable;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use function bin2hex;
use function hash_equals;
use function is_array;
use function is_int;
use function is_string;
use function json_decode;
use function json_encode;
use function random_bytes;

/**
 * The shared secret the web shop sends with stock updates (`X-Stock-Token`). Generated in the
 * admin and kept in the database; the env var STOCK_UPDATE_TOKEN is only used until one is
 * generated there. Also remembers the last update that came in, for the admin to see.
 *
 * @phpstan-import-type StockUpdateResult from StockUpdateService
 */
final readonly class StockTokenService
{
    private const string TOKEN = 'stock_update_token';
    private const string LAST_UPDATE = 'stock_last_update';

    public function __construct(
        private SettingRepository $settings,
        #[Autowire(env: 'STOCK_UPDATE_TOKEN')]
        private string $envToken = '',
    ) {}

    /**
     * The current token, or null when there's none (stock updates are then refused).
     */
    public function token(): ?string
    {
        $setting = $this->settings->find(self::TOKEN);
        if ($setting !== null) {
            return $setting->value;
        }

        return $this->envToken !== '' ? $this->envToken : null;
    }

    /**
     * Where the token comes from: generated in the admin (with when), the env var, or nowhere.
     *
     * @return array{source: 'admin'|'env'|null, since: ?DateTimeImmutable}
     */
    public function origin(): array
    {
        $setting = $this->settings->find(self::TOKEN);
        if ($setting !== null) {
            return ['source' => 'admin', 'since' => $setting->updatedAt];
        }

        return ['source' => $this->envToken !== '' ? 'env' : null, 'since' => null];
    }

    /**
     * Makes a new token, replacing the old one right away: the shop needs the new one.
     */
    public function generate(): string
    {
        $token = bin2hex(random_bytes(24));
        $this->settings->set(self::TOKEN, $token);

        return $token;
    }

    public function isValid(string $sent): bool
    {
        $token = $this->token();

        return $token !== null && $sent !== '' && hash_equals($token, $sent);
    }

    /**
     * @param StockUpdateResult $result
     */
    public function recordUpdate(array $result): void
    {
        $this->settings->set(self::LAST_UPDATE, (string) json_encode([
            'at' => new DateTimeImmutable()->format(DATE_ATOM),
            'result' => $result,
        ]));
    }

    /**
     * The last stock update that came in: when, and what it did. Null before the first.
     *
     * @return ?array{at: DateTimeImmutable, result: array<string, int>}
     */
    public function lastUpdate(): ?array
    {
        $setting = $this->settings->find(self::LAST_UPDATE);
        $data = $setting instanceof Setting ? json_decode($setting->value, true) : null;
        if (!is_array($data) || !is_string($data['at'] ?? null) || !is_array($data['result'] ?? null)) {
            return null;
        }

        $result = [];
        foreach ($data['result'] as $key => $count) {
            $result[(string) $key] = is_int($count) ? $count : 0;
        }

        return ['at' => new DateTimeImmutable($data['at']), 'result' => $result];
    }
}
