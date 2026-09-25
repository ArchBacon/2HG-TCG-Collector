<?php declare(strict_types=1);

namespace App\Security;

use App\Entity\User;
use App\Repository\UserRepository;
use DateTimeImmutable;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Security\Core\Authentication\Token\TokenInterface;
use Symfony\Component\Security\Core\Exception\AuthenticationException;
use Symfony\Component\Security\Core\Exception\BadCredentialsException;
use Symfony\Component\Security\Http\Authenticator\AbstractAuthenticator;
use Symfony\Component\Security\Http\Authenticator\Passport\Badge\UserBadge;
use Symfony\Component\Security\Http\Authenticator\Passport\Passport;
use Symfony\Component\Security\Http\Authenticator\Passport\SelfValidatingPassport;
use Symfony\Component\Security\Http\EntryPoint\AuthenticationEntryPointInterface;
use Symfony\Component\Uid\Uuid;

/**
 * Authenticates anonymous app users by `Authorization: Bearer <userId>.<secret>`, as returned by
 * {@see \App\Controller\UserController::create()}.
 *
 * Only runs when a bearer header is present, so public endpoints (cards, sets, user creation)
 * keep working without one. Endpoints that need a user guard themselves with
 * `#[IsGranted('ROLE_USER')]`, which gets a JSON 401 from {@see self::start()} when no token was sent.
 */
final class ApiTokenAuthenticator extends AbstractAuthenticator implements AuthenticationEntryPointInterface
{
    /** How stale {@see User::$lastSeenAt} may get before a request bumps it, to avoid a write per request. */
    private const string LAST_SEEN_RESOLUTION = '-1 hour';

    public function __construct(
        private readonly UserRepository $users,
        private readonly EntityManagerInterface $entityManager,
    ) {}

    public function supports(Request $request): bool
    {
        return str_starts_with($request->headers->get('Authorization', ''), 'Bearer ');
    }

    public function authenticate(Request $request): Passport
    {
        $token = substr($request->headers->get('Authorization', ''), 7);
        [$userId, $secret] = explode('.', $token, 2) + [1 => ''];

        if ($secret === '' || !Uuid::isValid($userId)) {
            throw new BadCredentialsException('Malformed API token.');
        }

        return new SelfValidatingPassport(new UserBadge($userId, function (string $userId) use ($secret): User {
            $user = $this->users->find(Uuid::fromString($userId));

            // Same error for an unknown user and a wrong secret, so the response doesn't reveal which ids exist.
            if ($user === null || !$user->verifySecret($secret)) {
                throw new BadCredentialsException('Invalid API token.');
            }

            return $user;
        }));
    }

    public function onAuthenticationSuccess(Request $request, TokenInterface $token, string $firewallName): ?Response
    {
        $user = $token->getUser();
        $now = new DateTimeImmutable();

        if ($user instanceof User && $user->lastSeenAt < $now->modify(self::LAST_SEEN_RESOLUTION)) {
            $user->lastSeenAt = $now;
            $this->entityManager->flush();
        }

        return null;
    }

    public function onAuthenticationFailure(Request $request, AuthenticationException $exception): Response
    {
        return new JsonResponse(['error' => $exception->getMessageKey()], Response::HTTP_UNAUTHORIZED);
    }

    public function start(Request $request, ?AuthenticationException $authException = null): Response
    {
        return new JsonResponse(['error' => 'Authentication required.'], Response::HTTP_UNAUTHORIZED);
    }
}
