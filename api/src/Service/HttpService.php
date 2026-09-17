<?php declare(strict_types=1);

namespace App\Service;

use App\Exception\HttpResponseException;
use RuntimeException;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\Process\Process;
use Symfony\Component\Uid\Uuid;
use Symfony\Component\Uid\UuidV4;
use Symfony\Contracts\HttpClient\Exception\ClientExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\DecodingExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\RedirectionExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\ServerExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface;
use Symfony\Contracts\HttpClient\HttpClientInterface;
use Symfony\Contracts\HttpClient\ResponseInterface;

final readonly class HttpService
{
    public function __construct(
        private HttpClientInterface $http,
        #[Autowire('%storage_dir%')]
        private string $storageDir,
    ) {}

    /**
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws DecodingExceptionInterface
     * @throws ClientExceptionInterface
     */
    public function json(string $url): array
    {
        $response = $this->http->request('GET', $url);
        $this->validateResponse($response);

        return $response->toArray();
    }

    /**
     * @throws TransportExceptionInterface
     * @throws ServerExceptionInterface
     * @throws RedirectionExceptionInterface
     * @throws ClientExceptionInterface
     */
    public function image(string $url): string
    {
        $response = $this->http->request('GET', $url);
        $this->validateResponse($response);

        return $response->getContent();
    }

    /**
     * @throws TransportExceptionInterface
     */
    public function zip(string $url): string
    {
        $response = $this->http->request('GET', $url);
        $this->validateResponse($response);
        $path = $this->storageDir . '/' . Uuid::v4() . '.zip';

        $fileHandler = fopen($path, 'wb');
        foreach ($this->http->stream($response) as $chunk) {
            fwrite($fileHandler, $chunk->getContent());
        }
        fclose($fileHandler);

        return $path;
    }

    public function download(string $downloadLink, string $filename): string
    {
        $outputPath = $this->storageDir . DIRECTORY_SEPARATOR . $filename;
        $process = new Process([
            'curl',
            '-f',
            '-o', $outputPath,
            $downloadLink
        ]);
        $process->setTimeout(600);
        $process->run();

        if (!$process->isSuccessful()) {
            throw new RuntimeException('curl failed: ' . $process->getErrorOutput());
        }

        return $outputPath;
    }

    /**
     * @throws TransportExceptionInterface
     */
    private function validateResponse(ResponseInterface $response): void
    {
        if ($response->getStatusCode() === 404) {
            throw new HttpResponseException("Resource not found. ({$response->getInfo()['url']})");
        }

        if ($response->getStatusCode() !== 200) {
            throw new HttpResponseException("Could not connect to {$response->getInfo()['url']}.");
        }
    }
}
