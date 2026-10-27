<?php declare(strict_types=1);

namespace App\Entity;

use App\Repository\SettingRepository;
use DateTimeImmutable;
use Doctrine\ORM\Mapping as ORM;

/**
 * A value the admin sets at runtime, by name (e.g. the stock feed's token): things that would
 * otherwise need an env var and a redeploy to change.
 */
#[ORM\Entity(repositoryClass: SettingRepository::class)]
#[ORM\Table(name: 'app_setting')]
class Setting
{
    #[ORM\Id]
    #[ORM\Column(type: 'string', length: 64)]
    public private(set) string $name;

    #[ORM\Column(type: 'text')]
    public string $value {
        get => $this->value;
        set {
            $this->value = $value;
            $this->updatedAt = new DateTimeImmutable();
        }
    }

    #[ORM\Column]
    public private(set) DateTimeImmutable $updatedAt;

    public function __construct(string $name, string $value)
    {
        $this->name = $name;
        $this->value = $value;
    }
}
