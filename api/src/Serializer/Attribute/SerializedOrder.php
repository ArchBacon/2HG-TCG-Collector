<?php declare(strict_types=1);

namespace App\Serializer\Attribute;

use Attribute;

/**
 * Declares the property order the API should serialize a class's fields in. Without this, a
 * class extending a shared base (e.g. {@see \App\ApiResource\Card}) always has its own
 * properties serialized after every inherited one — the Serializer's class metadata factory
 * merges a parent's attribute metadata before the child's own, regardless of where properties
 * are actually declared. {@see \App\Serializer\OrderedNormalizer} reads this attribute and
 * reorders the normalized output to match.
 */
#[Attribute(Attribute::TARGET_CLASS)]
final readonly class SerializedOrder
{
    /**
     * @param list<string> $order Property names in the order they should appear. Names not
     *        listed keep their original relative position among the remaining keys, which are
     *        placed after every listed one.
     */
    public function __construct(
        public array $order,
    ) {}
}
