<?php declare(strict_types=1);

namespace App\Service;

use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface;
use Symfony\Contracts\HttpClient\HttpClientInterface;
use function bin2hex;
use function random_bytes;

/**
 * Card recognition through the Magic Sorter image API, the same call the internal scanner app
 * makes. The app sends its scans here instead of to Magic Sorter directly, so the credentials
 * stay on the server.
 */
final readonly class MagicSorterClient
{
    private const string BASE_URL = 'https://api2.magic-sorter.com';
    private const int TIMEOUT_SECONDS = 15;

    public function __construct(
        private HttpClientInterface $http,
        #[Autowire(env: 'MAGIC_SORTER_DEVICE_ID')]
        private string $deviceId,
        #[Autowire(env: 'MAGIC_SORTER_API_TOKEN')]
        private string $apiToken,
        #[Autowire(env: 'MAGIC_SORTER_USER_AGENT')]
        private string $userAgent,
    ) {}

    public function isConfigured(): bool
    {
        return $this->deviceId !== '' && $this->apiToken !== '' && $this->userAgent !== '';
    }

    /**
     * Sends a card image for identification and returns Magic Sorter's raw answer, unparsed.
     *
     * @param string $gameMode Magic Sorter's game segment, e.g. 'mtg', 'pokemon', 'lorcana'
     * @return array{status: int, body: string}
     * @throws TransportExceptionInterface on connection failures and timeouts
     */
    public function identify(string $gameMode, string $imageData, string $condition, string $language, bool $foil): array
    {
        // Built by hand: a single file field doesn't justify pulling in symfony/mime.
        $boundary = '----tcg' . bin2hex(random_bytes(12));
        $body = "--$boundary\r\n"
            . "Content-Disposition: form-data; name=\"image\"; filename=\"scan.jpg\"\r\n"
            . "Content-Type: application/octet-stream\r\n\r\n"
            . $imageData . "\r\n"
            . "--$boundary--\r\n";

        $response = $this->http->request('POST', self::BASE_URL . '/image/' . $gameMode, [
            'query' => [
                'set_type' => '2',
                'condition' => $condition,
                'lang' => $language,
                'foil' => $foil ? 'true' : 'false',
            ],
            'headers' => [
                'User-Agent' => $this->userAgent,
                'X-Auth' => $this->deviceId . ':' . $this->apiToken,
                'Content-Type' => 'multipart/form-data; boundary=' . $boundary,
            ],
            'body' => $body,
            'timeout' => self::TIMEOUT_SECONDS,
            // A recognition call isn't worth retrying; the app can just scan again.
            'max_retries' => 0,
        ]);

        return ['status' => $response->getStatusCode(), 'body' => $response->getContent(false)];
    }
}
