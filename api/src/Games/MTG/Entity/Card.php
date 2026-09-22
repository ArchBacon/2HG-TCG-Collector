<?php declare(strict_types=1);

namespace App\Games\MTG\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use App\Enum\Game;
use App\Games\MTG\Repository\CardRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\Groups;

/** TODO: organize api fields output order
 *
 * Add a way to control the property order of serialized API responses. Right now, properties inherited from parent classes appear at the bottom of the JSON output, because the Symfony Serializer merges parent class metadata after the child's.
 *
 * Implement an opt-in class attribute plus a normalizer that reorders the normalized output:
 *
 * 1. Create `App\Serializer\Attribute\SerializedOrder`, a class-level PHP attribute that takes an array of property names (`public readonly array $order`).
 *
 * 2. Create `App\Serializer\OrderedNormalizer` implementing `NormalizerInterface` and `NormalizerAwareInterface` (use `NormalizerAwareTrait`):
 * - `supportsNormalization`: true only for objects whose class has `#[SerializedOrder]` AND that haven't already been handled. Use a context flag keyed by `spl_object_id($object)` to prevent infinite recursion.
 * - `normalize`: set the context flag, delegate to `$this->normalizer->normalize(...)`, then if the result is an array:
 * - keep any keys starting with `@` (JSON-LD/Hydra: @context, @id, @type) at the top in their original order
 * - then the keys listed in the attribute, in that order (skip ones not present)
 * - then all remaining keys in their original relative order
 * - (e.g. `array_replace(array_intersect_key(array_flip($order), $rest), $rest)`)
 * - `getSupportedTypes`: return `['object' => false]` (not cacheable, since support depends on context).
 * - Cache the reflection lookup of the attribute per class name.
 *
 * 3. Make sure it gets registered as a serializer normalizer (autoconfigure should handle this) and that it runs BEFORE ObjectNormalizer and, if API Platform is used, before API Platform's item normalizers. Check the priority with `bin/console debug:container --tag=serializer.normalizer` and set an explicit priority if needed.
 *
 * Before writing code:
 * - Check the Symfony version and whether API Platform is installed, and adapt method signatures accordingly (e.g. return types, whether getSupportedTypes exists).
 * - Look at the entities/resources that extend a base class and show me which ones are affected. Propose a sensible order for each (typically id first, then the class's own fields, then timestamps like createdAt/updatedAt last), but let me confirm before applying the attribute.
 *
 * After implementing:
 * - Apply `#[SerializedOrder([...])]` to the confirmed classes.
 * - Verify it works by hitting one or two endpoints (or writing a quick functional test) and showing the JSON key order before and after.
 * - Make sure nested/embedded objects of the same class and collections still serialize correctly.
 */

#[ApiResource(
    operations: [new GetCollection(), new Get()],
    routePrefix: '/mtg',
    normalizationContext: ['groups' => ['card:read']],
)]
#[ORM\Entity(repositoryClass: CardRepository::class)]
#[ORM\Table(name: 'tcg_card_mtg')]
final class Card extends \App\ApiResource\Card
{
    #[Groups(['card:read'])]
    public Game $tcg {
        get => Game::MagicTheGathering;
    }

    /** @var null|array{small: string; medium: string; large: string} */
    #[Groups(['card:read'])]
    public ?array $images {
        get => $this->hasImages ? [
            'small' => '/mtg/small/' . $this->id->toRfc4122() . '.webp',
            'medium' => '/mtg/medium/' . $this->id->toRfc4122() . '.webp',
            'large' => '/mtg/large/' . $this->id->toRfc4122() . '.webp',
        ] : null;
    }

    #[Groups(['card:read'])]
    #[ORM\ManyToOne(targetEntity: Set::class)]
    #[ORM\JoinColumn(name: 'set_id', referencedColumnName: 'id', nullable: false)]
    public Set $set {
        get => $this->set;
        set => $this->set = $value;
    }

    #[Groups(['card:read'])]
    #[ORM\Embedded(class: CardDetails::class)]
    public CardDetails $details {
        get => $this->details;
        set => $this->details = $value;
    }

    public function __construct(Set $set)
    {
        parent::__construct();
        $this->set = $set;
    }
}
