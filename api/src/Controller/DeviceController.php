<?php declare(strict_types=1);

namespace App\Controller;

use App\Entity\DeviceNotification;
use App\Entity\DeviceToken;
use App\Entity\User;
use App\Repository\DeviceNotificationRepository;
use App\Repository\DeviceTokenRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\CurrentUser;
use Symfony\Component\Security\Http\Attribute\IsGranted;

use function array_map;
use function in_array;
use function is_bool;
use function is_string;
use function strlen;

/**
 * The devices that get push notifications ({@see DeviceToken}). The app registers its Firebase
 * token on every start, when Firebase rotates it, and when the notification switch changes.
 */
#[Route('/api/users/devices')]
#[IsGranted('ROLE_USER')]
final class DeviceController
{
    /** Received notifications the app gets at most. */
    private const int RECEIVED_LIMIT = 100;

    public function __construct(
        private readonly DeviceTokenRepository $devices,
        private readonly DeviceNotificationRepository $received,
        private readonly EntityManagerInterface $entityManager,
    ) {}

    /**
     * Registers this device, or updates it. Body: `{"token": "<FID>", "platform": "android"
     * | "ios", "wishlistInStore": true, "announcements": true}`; all but the token are optional (the
     * switches default to on for a new device and stay as they were otherwise). A token another user had
     * (before a sync code moved the device) moves to this user. 204 on success.
     */
    #[Route('', methods: ['PUT'])]
    public function register(#[CurrentUser] User $user, Request $request): Response
    {
        $data = $request->toArray();
        $token = $data['token'] ?? null;
        if (!is_string($token) || $token === '' || strlen($token) > DeviceToken::MAX_TOKEN_LENGTH) {
            return new JsonResponse(['error' => 'Missing or invalid "token".'], Response::HTTP_BAD_REQUEST);
        }

        $device = $this->devices->findOneBy(['token' => $token]);
        if ($device === null) {
            $device = new DeviceToken($user, $token);
            $this->entityManager->persist($device);
        }
        $device->user = $user;

        $platform = $data['platform'] ?? null;
        if (is_string($platform) && in_array($platform, ['android', 'ios'], true)) {
            $device->platform = $platform;
        }
        if (is_bool($data['wishlistInStore'] ?? null)) {
            $device->wishlistInStore = $data['wishlistInStore'];
        }
        if (is_bool($data['announcements'] ?? null)) {
            $device->announcements = $data['announcements'];
        }
        $device->touchUpdatedAt(); // Last registered

        $this->entityManager->flush();

        return new Response(status: Response::HTTP_NO_CONTENT);
    }

    /**
     * The notifications this device received, newest first (the last {@see self::RECEIVED_LIMIT}),
     * and how many are unread. `?token=<FID>` names the device; one of another user is a 404.
     */
    #[Route('/notifications', methods: ['GET'])]
    public function notifications(#[CurrentUser] User $user, Request $request): JsonResponse
    {
        $device = $this->findOwnDevice($user, $request->query->getString('token'));

        return new JsonResponse([
            'unread' => $this->received->countUnread($device),
            'notifications' => array_map(static fn (DeviceNotification $n): array => [
                'id' => $n->id,
                'type' => $n->type,
                'title' => $n->title,
                'body' => $n->body,
                'route' => $n->route,
                'sentAt' => $n->sentAt->format(DATE_ATOM),
                'read' => $n->readAt !== null,
            ], $this->received->findForDevice($device, self::RECEIVED_LIMIT)),
        ]);
    }

    /**
     * Marks all of this device's notifications read (body: `{"token": "<FID>"}`). 204.
     */
    #[Route('/notifications/read', methods: ['POST'])]
    public function markAllRead(#[CurrentUser] User $user, Request $request): Response
    {
        $token = $request->toArray()['token'] ?? null;
        $this->received->markAllRead($this->findOwnDevice($user, is_string($token) ? $token : ''));

        return new Response(status: Response::HTTP_NO_CONTENT);
    }

    private function findOwnDevice(User $user, string $token): DeviceToken
    {
        return ($token !== '' ? $this->devices->findOneBy(['token' => $token, 'user' => $user]) : null)
            ?? throw new NotFoundHttpException('This device is not registered for notifications.');
    }

    /**
     * Forgets this device (body: `{"token": "..."}`): it gets no more notifications. 204, also when
     * it wasn't registered.
     */
    #[Route('', methods: ['DELETE'])]
    public function unregister(#[CurrentUser] User $user, Request $request): Response
    {
        $token = $request->toArray()['token'] ?? null;
        $device = is_string($token) ? $this->devices->findOneBy(['token' => $token, 'user' => $user]) : null;
        if ($device !== null) {
            $this->entityManager->remove($device);
            $this->entityManager->flush();
        }

        return new Response(status: Response::HTTP_NO_CONTENT);
    }
}
