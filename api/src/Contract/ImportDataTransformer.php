<?php declare(strict_types=1);

namespace App\Contract;

interface ImportDataTransformer
{
    /**
     * @param array<string, mixed> $raw
     * @return array<string, mixed>
     */
    public function transformSet(array $raw): array;

    /**
     * @param array<string, mixed> $raw
     * @return array{0: array<string, mixed>, 1: list<array<string, mixed>>}
     */
    public function transformCard(array $raw): array;
}
