<?php declare(strict_types=1);

namespace App\Service;

use JsonException;
use RuntimeException;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Contracts\HttpClient\Exception\ExceptionInterface;
use Symfony\Contracts\HttpClient\HttpClientInterface;
use Symfony\Contracts\HttpClient\ResponseInterface;

use function array_chunk;
use function base64_encode;
use function file_get_contents;
use function in_array;
use function is_array;
use function is_int;
use function is_file;
use function is_string;
use function json_decode;
use function json_encode;
use function openssl_sign;
use function rtrim;
use function preg_match;
use function strtr;
use function time;

/**
 * Sends push notifications with Firebase Cloud Messaging's HTTP v1 API, as the Firebase project's
 * service account: the JSON key from the Firebase console (Project settings, Service accounts),
 * at the path in env FIREBASE_CREDENTIALS (relative to the API folder, or absolute). Empty or no
 * file there means not set up: {@see self::isConfigured()} is false and nothing can be sent.
 *
 * Signs its own OAuth token (a JWT, RS256 with OpenSSL) rather than using the Firebase SDK for
 * PHP, which needs the sodium extension. The token is kept for the run, up to its hour.
 */
final class FcmClient
{
    private const string SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

    /** Requests in flight at once in {@see self::sendMany()}. */
    private const int CONCURRENCY = 100;

    /** Error codes for a token that will never work again: delete it. */
    private const array DEAD_TOKEN_CODES = ['UNREGISTERED', 'SENDER_ID_MISMATCH'];

    /** @var array{project_id: string, client_email: string, private_key: string, token_uri: string}|null */
    private ?array $credentials = null;

    private ?string $accessToken = null;
    private int $accessTokenExpiresAt = 0;

    /** The key's path, absolute; empty when not set. */
    private readonly string $credentialsPath;

    /**
     * @param string $credentialsPath absolute, or relative to the API folder ($projectDir)
     */
    public function __construct(
        private readonly HttpClientInterface $httpClient,
        #[Autowire(env: 'FIREBASE_CREDENTIALS')]
        string $credentialsPath = '',
        #[Autowire('%kernel.project_dir%')]
        string $projectDir = '',
    ) {
        $isAbsolute = $credentialsPath === '' || preg_match('#^([a-zA-Z]:)?[/\\\\]#', $credentialsPath) === 1;
        $this->credentialsPath = $isAbsolute ? $credentialsPath : rtrim($projectDir, '/\\') . '/' . $credentialsPath;
    }

    public function isConfigured(): bool
    {
        return $this->credentialsPath !== '' && is_file($this->credentialsPath);
    }

    /**
     * Sends a notification to one device, by its Firebase Installation ID ($fid, what the app's
     * FirebaseMessaging.onRegistered gives; FCM replaced registration tokens with it). $data is
     * for the app (strings only, as FCM wants). $channel is the Android notification channel the
     * app made (MainActivity): `wishlist` or `news`.
     *
     * @param array<string, string> $data
     */
    public function send(string $fid, string $title, string $body, array $data = [], string $channel = 'wishlist'): FcmResult
    {
        return $this->result($this->request($fid, $title, $body, $data, $channel));
    }

    /**
     * {@see self::send()} to many devices, {@see self::CONCURRENCY} requests at a time. Returns
     * the result per FID.
     *
     * @param list<string> $fids
     * @param array<string, string> $data
     *
     * @return array<string, FcmResult>
     */
    public function sendMany(array $fids, string $title, string $body, array $data = [], string $channel = 'wishlist'): array
    {
        $results = [];
        foreach (array_chunk($fids, self::CONCURRENCY) as $chunk) {
            // Requests start right away and run side by side; reading a result waits for it
            $responses = [];
            foreach ($chunk as $fid) {
                $responses[$fid] = $this->request($fid, $title, $body, $data, $channel);
            }
            foreach ($responses as $fid => $response) {
                $results[$fid] = $this->result($response);
            }
        }

        return $results;
    }

    /**
     * @param array<string, string> $data
     */
    private function request(string $fid, string $title, string $body, array $data, string $channel): ResponseInterface
    {
        $credentials = $this->credentials();

        $message = [
            'fid' => $fid,
            'notification' => ['title' => $title, 'body' => $body],
            'android' => ['notification' => ['channel_id' => $channel]],
            'apns' => ['payload' => ['aps' => ['sound' => 'default']]],
        ];
        if ($data !== []) {
            $message['data'] = $data;
        }

        return $this->httpClient->request(
            'POST',
            "https://fcm.googleapis.com/v1/projects/{$credentials['project_id']}/messages:send",
            ['auth_bearer' => $this->accessToken(), 'json' => ['message' => $message]],
        );
    }

    private function result(ResponseInterface $response): FcmResult
    {
        try {
            $status = $response->getStatusCode();
            if ($status === 200) {
                return FcmResult::sent();
            }
            $error = $response->toArray(false)['error'] ?? [];
        } catch (ExceptionInterface $e) {
            return FcmResult::failed($e->getMessage());
        }

        $code = self::errorCode(is_array($error) ? $error : []);
        $message = is_array($error) && is_string($error['message'] ?? null) ? $error['message'] : "HTTP $status";
        $isDead = in_array($code, self::DEAD_TOKEN_CODES, true)
            || ($code === 'INVALID_ARGUMENT' && preg_match('/registration token|installation id|\bfid\b/i', $message) === 1);

        return $isDead ? FcmResult::invalidToken("$code: $message") : FcmResult::failed("$code: $message");
    }

    /**
     * The FCM error code from an error response, e.g. UNREGISTERED; else its status.
     *
     * @param array<mixed> $error
     */
    private static function errorCode(array $error): string
    {
        foreach ((array) ($error['details'] ?? []) as $detail) {
            if (is_array($detail) && is_string($detail['errorCode'] ?? null)) {
                return $detail['errorCode'];
            }
        }

        return is_string($error['status'] ?? null) ? $error['status'] : 'UNKNOWN';
    }

    private function accessToken(): string
    {
        if ($this->accessToken !== null && time() < $this->accessTokenExpiresAt - 60) {
            return $this->accessToken;
        }

        $credentials = $this->credentials();
        $now = time();
        $jwt = self::signJwt(
            ['alg' => 'RS256', 'typ' => 'JWT'],
            [
                'iss' => $credentials['client_email'],
                'scope' => self::SCOPE,
                'aud' => $credentials['token_uri'],
                'iat' => $now,
                'exp' => $now + 3600,
            ],
            $credentials['private_key'],
        );

        try {
            $data = $this->httpClient->request('POST', $credentials['token_uri'], [
                'body' => ['grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer', 'assertion' => $jwt],
            ])->toArray(false);
        } catch (ExceptionInterface $e) {
            throw new RuntimeException('Getting a Firebase access token failed: ' . $e->getMessage(), previous: $e);
        }

        if (!is_string($data['access_token'] ?? null)) {
            // E.g. invalid_grant: the key was deleted or belongs to another project
            $error = is_string($data['error_description'] ?? null) ? $data['error_description'] : (is_string($data['error'] ?? null) ? $data['error'] : 'no access_token in the answer');
            throw new RuntimeException("Getting a Firebase access token failed: $error.");
        }
        $this->accessToken = $data['access_token'];
        $this->accessTokenExpiresAt = $now + (is_int($data['expires_in'] ?? null) ? $data['expires_in'] : 3600);

        return $this->accessToken;
    }

    /**
     * @return array{project_id: string, client_email: string, private_key: string, token_uri: string}
     */
    private function credentials(): array
    {
        if ($this->credentials !== null) {
            return $this->credentials;
        }
        if (!$this->isConfigured()) {
            throw new RuntimeException('Firebase is not set up: FIREBASE_CREDENTIALS must be the path to the service account key (JSON).');
        }

        try {
            $json = json_decode((string) file_get_contents($this->credentialsPath), true, flags: JSON_THROW_ON_ERROR);
        } catch (JsonException $e) {
            throw new RuntimeException('The Firebase service account key is not valid JSON.', previous: $e);
        }

        foreach (['project_id', 'client_email', 'private_key'] as $key) {
            if (!is_array($json) || !is_string($json[$key] ?? null)) {
                throw new RuntimeException("The Firebase service account key has no \"$key\"; is it the service account's JSON key?");
            }
        }

        return $this->credentials = [
            'project_id' => $json['project_id'],
            'client_email' => $json['client_email'],
            'private_key' => $json['private_key'],
            'token_uri' => is_string($json['token_uri'] ?? null) ? $json['token_uri'] : 'https://oauth2.googleapis.com/token',
        ];
    }

    /**
     * @param array<string, mixed> $header
     * @param array<string, mixed> $claims
     */
    private static function signJwt(array $header, array $claims, string $privateKey): string
    {
        $input = self::base64Url((string) json_encode($header)) . '.' . self::base64Url((string) json_encode($claims));
        if (!openssl_sign($input, $signature, $privateKey, OPENSSL_ALGO_SHA256) || !is_string($signature)) {
            throw new RuntimeException('Signing the Firebase token failed; is the private key in the service account key intact?');
        }

        return $input . '.' . self::base64Url($signature);
    }

    private static function base64Url(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
}
