<?php declare(strict_types=1);

namespace App\Controller;

use App\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\CurrentUser;
use Symfony\Component\Security\Http\Attribute\IsGranted;

/**
 * Anonymous user endpoints. The app calls {@see self::create()} once on first startup and stores
 * the returned token; every later request sends it as `Authorization: Bearer <token>`.
 */
#[Route('/api/users')]
final class UserController
{
    public function __construct(
        private readonly EntityManagerInterface $entityManager,
    ) {}

    /**
     * Creates a new anonymous user. The token is only ever returned here; the server keeps just a
     * hash of its secret part, so a device that loses it has to create a new user.
     */
    #[Route('', methods: ['POST'])]
    public function create(): JsonResponse
    {
        $secret = User::generateSecret();
        $user = new User(User::hashSecret($secret));

        $this->entityManager->persist($user);
        $this->entityManager->flush();

        return new JsonResponse([
            'id' => $user->id->toRfc4122(),
            'token' => $user->id->toRfc4122() . '.' . $secret,
        ], Response::HTTP_CREATED);
    }

    /**
     * Returns the authenticated user, e.g. for the app to check its stored token is still valid.
     */
    #[Route('/validate', methods: ['GET'])]
    #[IsGranted('ROLE_USER')]
    public function me(#[CurrentUser] User $user): JsonResponse
    {
        return new JsonResponse([
            'id' => $user->id->toRfc4122(),
            'createdAt' => $user->createdAt->format(DATE_ATOM),
        ]);
    }
}
