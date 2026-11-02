<?php declare(strict_types=1);

namespace App\Service;

use App\Entity\Announcement;
use App\Entity\DeviceNotification;
use App\Repository\AnnouncementRepository;
use App\Repository\DeviceNotificationRepository;
use App\Repository\DeviceTokenRepository;
use DateTimeImmutable;
use Doctrine\ORM\EntityManagerInterface;
use Throwable;

use function array_values;
use function count;

/**
 * Sends the admin's {@see Announcement}s once due: to their audience
 * ({@see DeviceTokenRepository::findForAnnouncement()}), on the Android "news" channel. Run by
 * `api:notifications` from cron, and started right away by the admin's "Send now".
 */
final readonly class AnnouncementSender
{
    public function __construct(
        private AnnouncementRepository $announcements,
        private DeviceTokenRepository $devices,
        private DeviceNotificationRepository $received,
        private FcmClient $fcm,
        private EntityManagerInterface $entityManager,
    ) {}

    /**
     * Sends every announcement that is due. Each is claimed first, so overlapping runs never send
     * one twice. Returns per announcement sent: its title and the devices it reached.
     *
     * @return list<array{title: string, devices: int, failures: int, error: ?string}>
     */
    public function sendDue(): array
    {
        $results = [];
        foreach ($this->announcements->findDue(new DateTimeImmutable()) as $announcement) {
            if (!$this->announcements->claim($announcement)) {
                continue;
            }

            try {
                $this->send($announcement);
            } catch (Throwable $e) {
                $announcement->markFailed($e->getMessage());
            }
            $this->entityManager->flush();

            $results[] = [
                'title' => $announcement->title,
                'devices' => $announcement->devices,
                'failures' => $announcement->failures,
                'error' => $announcement->error,
            ];
        }

        return $results;
    }

    private function send(Announcement $announcement): void
    {
        $audience = $this->devices->findForAnnouncement($announcement); // Device id => token
        $data = ['type' => 'announcement'];
        if ($announcement->route !== null) {
            $data['route'] = $announcement->route;
        }

        $results = $this->fcm->sendMany(array_values($audience), $announcement->title, $announcement->body, $data, 'news');

        $sent = 0;
        $sentTo = [];
        $failures = 0;
        $firstError = null;
        $deadIds = [];
        foreach ($audience as $id => $token) {
            $result = $results[$token] ?? null;
            if ($result?->sent) {
                $sent++;
                $sentTo[] = $id;
            } elseif ($result?->invalidToken) {
                $deadIds[] = $id;
            } else {
                $failures++;
                $firstError ??= $result->error ?? 'No result';
            }
        }

        // For the app's list of received notifications
        $this->received->record($sentTo, DeviceNotification::ANNOUNCEMENT, $announcement->title, $announcement->body, $announcement->route);

        if ($deadIds !== []) {
            $this->entityManager->createQuery('DELETE FROM App\Entity\DeviceToken d WHERE d.id IN (:ids)')
                ->setParameter('ids', $deadIds)
                ->execute();
        }

        if ($sent === 0 && $failures > 0) {
            $announcement->markFailed(count($audience) . " devices, none reached: $firstError");
            return;
        }
        $announcement->markSent($sent, $failures);
    }
}
