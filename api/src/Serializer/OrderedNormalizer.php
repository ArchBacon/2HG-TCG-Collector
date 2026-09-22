<?php declare(strict_types=1);

namespace App\Serializer;

use ArrayObject;
use App\Serializer\Attribute\SerializedOrder;
use ReflectionClass;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\DependencyInjection\Attribute\AsTaggedItem;
use Symfony\Component\Serializer\NameConverter\NameConverterInterface;
use Symfony\Component\Serializer\Normalizer\NormalizerAwareInterface;
use Symfony\Component\Serializer\Normalizer\NormalizerAwareTrait;
use Symfony\Component\Serializer\Normalizer\NormalizerInterface;

/**
 * Reorders normalized output for classes tagged with {@see SerializedOrder} — see that
 * attribute for why this is needed. This normalizer doesn't do any normalizing of its own: it
 * runs ahead of the "real" normalizers (id="serializer.normalizer" priority, set via
 * {@see AsTaggedItem} below) purely to intercept eligible objects, delegate to the rest of the
 * chain as normal, and rearrange the resulting array before handing it back.
 */
#[AsTaggedItem(priority: 100)]
final class OrderedNormalizer implements NormalizerInterface, NormalizerAwareInterface
{
    use NormalizerAwareTrait;

    private const string ALREADY_CALLED = self::class . '::alreadyCalled';

    /** @var array<class-string, list<string>|null> */
    private array $orderByClass = [];

    public function __construct(
        // The same name converter ObjectNormalizer itself resolves to (config/packages/
        // serializer.yaml + api_platform.yaml both point 'name_converter' at
        // camel_case_to_snake_case) — SerializedOrder's $order lists PHP property names, but the
        // normalized array is keyed by whatever this converts them to (e.g. 'typeLine' ->
        // 'type_line'), so the two must agree or a multi-word name just silently never matches.
        #[Autowire(service: 'serializer.name_converter.metadata_aware')]
        private readonly ?NameConverterInterface $nameConverter = null,
    ) {}

    public function supportsNormalization(mixed $data, ?string $format = null, array $context = []): bool
    {
        if (!is_object($data) || ($context[self::ALREADY_CALLED][spl_object_id($data)] ?? false)) {
            return false;
        }

        return $this->orderFor($data::class) !== null;
    }

    /**
     * Depends on the concrete object's class (via {@see orderFor}) and on context (the
     * already-called guard), neither of which the cache key this return value feeds can
     * express, so it can't be cached.
     */
    public function getSupportedTypes(?string $format): array
    {
        return ['object' => false];
    }

    public function normalize(mixed $data, ?string $format = null, array $context = []): array|string|int|float|bool|ArrayObject|null
    {
        // Guards against infinite recursion into ourselves via the delegate call below, keyed
        // by object identity (not class) so sibling instances of the same class are unaffected.
        $context[self::ALREADY_CALLED][spl_object_id($data)] = true;
        $result = $this->normalizer->normalize($data, $format, $context);

        if (!is_array($result)) {
            return $result;
        }

        // JSON-LD/Hydra's @context/@id/@type, if present, stay first and in their original order.
        $meta = array_filter($result, static fn (string $key): bool => str_starts_with($key, '@'), ARRAY_FILTER_USE_KEY);
        $rest = array_diff_key($result, $meta);

        // array_replace keeps the key order of its first argument, so this puts every key from
        // $order (that's actually present) first in that order, then array_replace's "unknown
        // key" behavior appends whatever's left from $rest afterwards, in $rest's own order.
        $order = $this->orderFor($data::class) ?? [];
        $reordered = array_replace(array_intersect_key(array_flip($order), $rest), $rest);

        return $meta + $reordered;
    }

    /** @return list<string>|null property names as they appear in the normalized array */
    private function orderFor(string $class): ?array
    {
        if (!array_key_exists($class, $this->orderByClass)) {
            $attributes = (new ReflectionClass($class))->getAttributes(SerializedOrder::class);
            $order = $attributes === [] ? null : $attributes[0]->newInstance()->order;

            $this->orderByClass[$class] = $order === null || $this->nameConverter === null
                ? $order
                : array_map(fn (string $name): string => $this->nameConverter->normalize($name, $class), $order);
        }

        return $this->orderByClass[$class];
    }
}
