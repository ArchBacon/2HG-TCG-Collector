<?php declare(strict_types=1);

namespace App\Service;

use Symfony\Component\DependencyInjection\Attribute\Autowire;

final readonly class LanguageService
{
    /** @var list<string> */
    private array $supportedLanguages;

    /** @param list<string> $supportedLanguages */
    public function __construct(
        #[Autowire('%supported_languages%')]
        array $supportedLanguages,
    ) {
        $this->supportedLanguages = array_values(array_filter(
            $supportedLanguages,
            static fn (?string $lang): bool => $lang !== null && $lang !== '',
        ));
    }

    public function isSupported(string $lang): bool
    {
        return in_array($lang, $this->supportedLanguages, true);
    }

    /** @return list<string> */
    public function getSupportedLanguages(): array
    {
        return $this->supportedLanguages;
    }
}
