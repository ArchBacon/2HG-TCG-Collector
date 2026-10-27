<?php declare(strict_types=1);

namespace App\Controller\Admin;

use App\Enum\Game;
use App\Service\AdminJobService;
use DateTimeImmutable;
use InvalidArgumentException;
use RuntimeException;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Routing\Requirement\Requirement;

use function sprintf;

/**
 * Run the sync commands (and the cron ones) from the admin, one at a time with the next ones
 * queued, and follow their output live, like in a console.
 */
#[Route('/admin/sync')]
final class AdminSyncController extends AbstractController
{
    public function __construct(
        private readonly AdminJobService $jobs,
        #[Autowire('%kernel.project_dir%')]
        private readonly string $projectDir,
    ) {}

    #[Route('', name: 'admin_sync', methods: ['GET'])]
    public function index(): Response
    {
        $this->jobs->startNext(); // In case the runner of the last job died before it could

        $jobs = array_filter($this->jobs->all(), fn (array $job): bool => !$this->jobs->isQueued($job));

        return $this->render('admin/sync/index.html.twig', [
            'games' => Game::cases(),
            'imageModes' => AdminJobService::IMAGE_MODES,
            'defaultRunAt' => $this->jobs->defaultRunAt(),
            'timezone' => $this->jobs->timezone()->getName(),
            'running' => $this->jobs->running(),
            'queue' => $this->jobs->queued(),
            'cronJobs' => AdminJobService::CRON_JOBS,
            'projectDir' => $this->projectDir,
            'jobs' => array_map(fn (array $job): array => [...$job, 'running' => $this->jobs->isRunning($job)], $jobs),
        ]);
    }

    #[Route('', name: 'admin_sync_start', methods: ['POST'])]
    public function start(Request $request): Response
    {
        if (!$this->isCsrfTokenValid('admin-sync', $request->request->getString('_token'))) {
            $this->addFlash('error', 'Session expired, please try again.');

            return $this->redirectToRoute('admin_sync');
        }

        try {
            $action = $this->jobs->action(
                $request->request->getString('action'),
                $request->request->getString('game'),
                $request->request->getString('images', 'new'),
            );
            $runAt = $request->request->getString('when') === 'scheduled' ? $this->runAt($request) : null;
            $job = $this->jobs->enqueue($action['label'], $action['args'], $runAt);
        } catch (InvalidArgumentException|RuntimeException $e) {
            $this->addFlash('error', $e->getMessage());

            return $this->redirectToRoute('admin_sync');
        }

        if ($runAt !== null) {
            $this->addFlash('success', sprintf('Scheduled: %s, on %s.', $job['label'], $runAt->format('j M Y \a\t H:i')));

            return $this->redirectToRoute('admin_sync');
        }
        if ($this->jobs->isQueued($job)) {
            $this->addFlash('success', sprintf('Queued: %s.', $job['label']));

            return $this->redirectToRoute('admin_sync');
        }

        return $this->redirectToRoute('admin_sync_show', ['id' => $job['id']]);
    }

    /**
     * The date and time from the form, in the admin's time zone.
     */
    private function runAt(Request $request): DateTimeImmutable
    {
        $value = sprintf('%s %s', $request->request->getString('date'), $request->request->getString('time'));
        $runAt = DateTimeImmutable::createFromFormat('!Y-m-d H:i', $value, $this->jobs->timezone());
        if ($runAt === false || $runAt->format('Y-m-d H:i') !== $value) {
            throw new InvalidArgumentException('Pick a valid date and time.');
        }

        return $runAt;
    }

    /**
     * Takes a job out of the queue, before it has started (scheduled ones too).
     */
    #[Route('/{id}/cancel', name: 'admin_sync_cancel', requirements: ['id' => Requirement::UUID], methods: ['POST'])]
    public function cancel(string $id, Request $request): Response
    {
        if (!$this->isCsrfTokenValid('admin-sync-cancel-' . $id, $request->request->getString('_token'))) {
            $this->addFlash('error', 'Session expired, please try again.');
        } elseif (!$this->jobs->cancel($id)) {
            $this->addFlash('error', 'That job has already started.');
        }

        return $this->redirectToRoute('admin_sync');
    }

    /**
     * Stops the running job. Its runner picks this up within a second; the page shows it finish.
     */
    #[Route('/{id}/stop', name: 'admin_sync_stop', requirements: ['id' => Requirement::UUID], methods: ['POST'])]
    public function stop(string $id, Request $request): Response
    {
        if (!$this->isCsrfTokenValid('admin-sync-stop-' . $id, $request->request->getString('_token'))) {
            $this->addFlash('error', 'Session expired, please try again.');
        } elseif (!$this->jobs->requestStop($id)) {
            $this->addFlash('error', "That job isn't running, or can't be stopped from here.");
        }

        return $this->redirectToRoute('admin_sync_show', ['id' => $id]);
    }

    #[Route('/{id}', name: 'admin_sync_show', requirements: ['id' => Requirement::UUID], methods: ['GET'])]
    public function show(string $id): Response
    {
        $job = $this->jobs->find($id) ?? throw new NotFoundHttpException();

        return $this->render('admin/sync/show.html.twig', [
            'job' => $job,
            'running' => $this->jobs->isRunning($job),
            'queued' => $this->jobs->isQueued($job),
            'stopping' => $this->jobs->isStopRequested($id),
        ]);
    }

    /**
     * New output since byte `offset`, for the page to append, and whether the job is done.
     */
    #[Route('/{id}/log', name: 'admin_sync_log', requirements: ['id' => Requirement::UUID], methods: ['GET'])]
    public function log(string $id, Request $request): JsonResponse
    {
        $this->jobs->startNext(); // In case the runner of the last job died before it could
        $job = $this->jobs->find($id) ?? throw new NotFoundHttpException(); // Gone: taken out of the queue

        return new JsonResponse([
            ...$this->jobs->readLog($id, max(0, $request->query->getInt('offset'))),
            'running' => $this->jobs->isRunning($job),
            'queued' => $this->jobs->isQueued($job),
            'exitCode' => $job['exitCode'],
            'finishedAt' => $job['finishedAt'],
        ]);
    }
}
