<?php declare(strict_types=1);

namespace App\Controller\Admin;

use App\Entity\Announcement;
use App\Enum\CardListType;
use App\Enum\Game;
use App\Repository\AnnouncementRepository;
use App\Repository\DeviceTokenRepository;
use App\Service\AdminJobService;
use App\Service\FcmClient;
use DateTimeImmutable;
use DateTimeZone;
use Doctrine\ORM\EntityManagerInterface;
use InvalidArgumentException;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Routing\Requirement\Requirement;

use function array_column;
use function array_filter;
use function array_intersect;
use function array_map;
use function array_values;
use function date_default_timezone_get;
use function is_string;
use function mb_strlen;
use function sprintf;
use function trim;

/**
 * Notifications written here and sent to the app ({@see Announcement}): to everyone, or to
 * collectors of some games; now or at a set time. Sent by `api:notifications` (cron) when due;
 * "Send now" starts that right away.
 */
#[Route('/admin/notifications')]
final class AdminNotificationController extends AbstractController
{
    private const int HISTORY = 30;

    public function __construct(
        private readonly AnnouncementRepository $announcements,
        private readonly DeviceTokenRepository $devices,
        private readonly AdminJobService $jobs,
        private readonly FcmClient $fcm,
        private readonly EntityManagerInterface $entityManager,
    ) {}

    #[Route('', name: 'admin_notifications', methods: ['GET'])]
    public function index(): Response
    {
        $this->sendDueNow(); // In case cron isn't running (development): sends what is overdue

        $list = $this->announcements->findForAdmin(self::HISTORY);

        return $this->render('admin/notifications/index.html.twig', [
            ...$this->formOptions(),
            'scheduled' => array_map(fn (Announcement $a): array => ['announcement' => $a, 'audience' => $this->devices->countForAnnouncement($a)], $list['scheduled']),
            'past' => $list['past'],
            'configured' => $this->fcm->isConfigured(),
        ]);
    }

    #[Route('', name: 'admin_notifications_create', methods: ['POST'])]
    public function create(Request $request): Response
    {
        if (!$this->isCsrfTokenValid('admin-notification', $request->request->getString('_token'))) {
            $this->addFlash('error', 'Session expired, please try again.');
            return $this->redirectToRoute('admin_notifications');
        }

        $announcement = new Announcement('', '', new DateTimeImmutable(), $this->getUser()?->getUserIdentifier() ?? 'admin');
        try {
            $sendNow = $this->fill($announcement, $request);
        } catch (InvalidArgumentException $e) {
            $this->addFlash('error', $e->getMessage());
            return $this->redirectToRoute('admin_notifications');
        }

        $this->entityManager->persist($announcement);
        $this->entityManager->flush();

        return $this->afterSave($announcement, $sendNow);
    }

    #[Route('/{id}/edit', name: 'admin_notifications_edit', requirements: ['id' => Requirement::DIGITS], methods: ['GET'])]
    public function edit(int $id): Response
    {
        $announcement = $this->findScheduled($id);

        return $this->render('admin/notifications/edit.html.twig', [
            ...$this->formOptions(),
            'announcement' => $announcement,
        ]);
    }

    #[Route('/{id}/edit', name: 'admin_notifications_update', requirements: ['id' => Requirement::DIGITS], methods: ['POST'])]
    public function update(int $id, Request $request): Response
    {
        if (!$this->isCsrfTokenValid('admin-notification-' . $id, $request->request->getString('_token'))) {
            $this->addFlash('error', 'Session expired, please try again.');
            return $this->redirectToRoute('admin_notifications_edit', ['id' => $id]);
        }

        $announcement = $this->findScheduled($id);
        try {
            $sendNow = $this->fill($announcement, $request);
        } catch (InvalidArgumentException $e) {
            $this->addFlash('error', $e->getMessage());
            return $this->redirectToRoute('admin_notifications_edit', ['id' => $id]);
        }
        $this->entityManager->flush();

        return $this->afterSave($announcement, $sendNow);
    }

    #[Route('/{id}/cancel', name: 'admin_notifications_cancel', requirements: ['id' => Requirement::DIGITS], methods: ['POST'])]
    public function cancel(int $id, Request $request): Response
    {
        if (!$this->isCsrfTokenValid('admin-notification-cancel-' . $id, $request->request->getString('_token'))) {
            $this->addFlash('error', 'Session expired, please try again.');
        } else {
            $announcement = $this->announcements->find($id);
            if ($announcement?->isScheduled()) {
                $announcement->cancel();
                $this->entityManager->flush();
                $this->addFlash('success', sprintf('Cancelled "%s".', $announcement->title));
            } else {
                $this->addFlash('error', 'That notification is no longer scheduled.');
            }
        }

        return $this->redirectToRoute('admin_notifications');
    }

    /**
     * How many users and devices the form's audience reaches now, for the form to show as it changes.
     */
    #[Route('/audience', name: 'admin_notifications_audience', methods: ['POST'])]
    public function audience(Request $request): JsonResponse
    {
        $announcement = new Announcement('', '', new DateTimeImmutable(), '');
        try {
            $this->fillAudience($announcement, $request);
        } catch (InvalidArgumentException $e) {
            return new JsonResponse(['error' => $e->getMessage()]);
        }

        return new JsonResponse($this->devices->countForAnnouncement($announcement));
    }

    private function afterSave(Announcement $announcement, bool $sendNow): Response
    {
        if ($sendNow) {
            if (!$this->fcm->isConfigured()) {
                $this->addFlash('error', 'Saved, but Firebase is not set up (FIREBASE_CREDENTIALS), so it can\'t be sent yet.');
                return $this->redirectToRoute('admin_notifications');
            }
            $this->jobs->launch(['api:notifications', '--announcements']);
            $this->addFlash('success', sprintf('Sending "%s" now. Reload to see how far it reached.', $announcement->title));
        } else {
            $this->addFlash('success', sprintf(
                'Scheduled "%s" for %s.',
                $announcement->title,
                $announcement->sendAt->setTimezone($this->jobs->timezone())->format('j M Y \a\t H:i'),
            ));
        }

        return $this->redirectToRoute('admin_notifications');
    }

    /**
     * Fills $announcement from the form. Returns whether it's to be sent now.
     *
     * @throws InvalidArgumentException with what to fix
     */
    private function fill(Announcement $announcement, Request $request): bool
    {
        $title = trim($request->request->getString('title'));
        $body = trim($request->request->getString('body'));
        if ($title === '' || $body === '') {
            throw new InvalidArgumentException('Give it a title and a message.');
        }
        if (!mb_check_encoding($title . $body, 'UTF-8')) {
            throw new InvalidArgumentException('The text has characters that could not be read; please type it again.');
        }
        if (mb_strlen($title) > Announcement::MAX_TITLE || mb_strlen($body) > Announcement::MAX_BODY) {
            throw new InvalidArgumentException(sprintf('The title can be %d characters at most, the message %d.', Announcement::MAX_TITLE, Announcement::MAX_BODY));
        }

        $route = $request->request->getString('route');
        if (!isset(Announcement::ROUTES[$route])) {
            throw new InvalidArgumentException('Pick a page to open.');
        }

        $this->fillAudience($announcement, $request);
        $announcement->title = $title;
        $announcement->body = $body;
        $announcement->route = $route === '' ? null : $route;

        $sendNow = $request->request->getString('when') !== 'scheduled';
        $announcement->sendAt = $sendNow ? new DateTimeImmutable() : $this->sendAt($request);

        return $sendNow;
    }

    /**
     * @throws InvalidArgumentException
     */
    private function fillAudience(Announcement $announcement, Request $request): void
    {
        if ($request->request->getString('audience') !== 'collectors') {
            $announcement->games = [];
            return;
        }

        $all = $request->request->all();
        $games = array_values(array_intersect(self::strings($all['games'] ?? []), array_column(Game::cases(), 'value')));
        $lists = array_values(array_intersect(self::strings($all['lists'] ?? []), array_column(CardListType::cases(), 'value')));
        if ($games === []) {
            throw new InvalidArgumentException('Pick at least one game, or send it to everyone.');
        }
        if ($lists === []) {
            throw new InvalidArgumentException('Pick where they have those cards: collection, wishlist or both.');
        }

        $announcement->games = $games;
        $announcement->lists = $lists;
    }

    /**
     * The date and time from the form, in the admin's time zone; stored in the server's (UTC).
     *
     * @throws InvalidArgumentException
     */
    private function sendAt(Request $request): DateTimeImmutable
    {
        $value = sprintf('%s %s', $request->request->getString('date'), $request->request->getString('time'));
        $sendAt = DateTimeImmutable::createFromFormat('!Y-m-d H:i', $value, $this->jobs->timezone());
        if ($sendAt === false || $sendAt->format('Y-m-d H:i') !== $value) {
            throw new InvalidArgumentException('Pick a valid date and time.');
        }
        if ($sendAt <= new DateTimeImmutable()) {
            throw new InvalidArgumentException('Pick a time in the future, or send it now.');
        }

        return $sendAt->setTimezone(new DateTimeZone(date_default_timezone_get()));
    }

    private function findScheduled(int $id): Announcement
    {
        $announcement = $this->announcements->find($id) ?? throw new NotFoundHttpException();
        if (!$announcement->isScheduled()) {
            throw new NotFoundHttpException('Only scheduled notifications can be edited.');
        }

        return $announcement;
    }

    /**
     * Sends the overdue announcements in the background, when there are any.
     */
    private function sendDueNow(): void
    {
        if ($this->fcm->isConfigured() && $this->announcements->findDue(new DateTimeImmutable()) !== []) {
            $this->jobs->launch(['api:notifications', '--announcements']);
        }
    }

    /**
     * @return array<string, mixed>
     */
    private function formOptions(): array
    {
        return [
            'games' => Game::cases(),
            'lists' => [CardListType::Collection->value => 'Collection', CardListType::Wishlist->value => 'Wishlist'],
            'routes' => Announcement::ROUTES,
            'defaultSendAt' => $this->jobs->defaultRunAt()->setTime(10, 0),
            'timezone' => $this->jobs->timezone()->getName(),
            'maxTitle' => Announcement::MAX_TITLE,
            'maxBody' => Announcement::MAX_BODY,
        ];
    }

    /**
     * @return list<string>
     */
    private static function strings(mixed $values): array
    {
        return array_values(array_filter((array) $values, is_string(...)));
    }
}
