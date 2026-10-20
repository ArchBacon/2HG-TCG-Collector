<?php declare(strict_types=1);

namespace App\Controller\Admin;

use App\Enum\Game;
use App\Service\CardImageService;
use App\Service\MissingCardImageFinder;
use Doctrine\ORM\EntityManagerInterface;
use RuntimeException;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\File\UploadedFile;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Attribute\MapQueryParameter;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Uid\Uuid;
use function file_get_contents;
use function sprintf;

/**
 * Cards without (all sizes of) their image on disk, with a manual upload per card.
 */
#[Route('/admin/images')]
final class AdminCardImageController extends AbstractController
{
    private const int PAGE_SIZE = 50;
    private const int MAX_UPLOAD_BYTES = 10 * 1024 * 1024;

    public function __construct(
        private readonly MissingCardImageFinder $finder,
        private readonly CardImageService $images,
        private readonly EntityManagerInterface $entityManager,
    ) {}

    #[Route('', name: 'admin_images', methods: ['GET'])]
    public function index(
        #[MapQueryParameter] string $game = Game::MagicTheGathering->value,
        #[MapQueryParameter] int $page = 1,
    ): Response {
        $selected = Game::tryFrom($game) ?? Game::MagicTheGathering;
        $page = max(1, $page);
        ['total' => $total, 'cards' => $cards] = $this->finder->find($selected, ($page - 1) * self::PAGE_SIZE, self::PAGE_SIZE);

        return $this->render('admin/images/index.html.twig', [
            'cards' => $cards,
            'total' => $total,
            'page' => $page,
            'pageSize' => self::PAGE_SIZE,
            'game' => $selected,
            'games' => Game::cases(),
        ]);
    }

    #[Route('/{game}/{id}', name: 'admin_image_upload', methods: ['POST'])]
    public function upload(Game $game, string $id, Request $request): Response
    {
        $back = $this->redirectToRoute('admin_images', ['game' => $game->value, 'page' => $request->query->getInt('page', 1)]);

        if (!$this->isCsrfTokenValid('upload-image-' . $id, $request->request->getString('_token'))) {
            $this->addFlash('error', 'Session expired, please try again.');
            return $back;
        }

        if (!Uuid::isValid($id) || ($card = $this->entityManager->find($game->cardClass(), Uuid::fromString($id))) === null) {
            throw $this->createNotFoundException('Card not found.');
        }

        $file = $request->files->get('image');
        if (!$file instanceof UploadedFile || !$file->isValid()) {
            $this->addFlash('error', sprintf('Upload for "%s" failed: %s', $card->name, $file instanceof UploadedFile ? $file->getErrorMessage() : 'no file selected.'));
            return $back;
        }
        if ($file->getSize() > self::MAX_UPLOAD_BYTES) {
            $this->addFlash('error', sprintf('Image for "%s" is larger than 10 MB.', $card->name));
            return $back;
        }

        // Checked up front: GD only warns on undecodable data, which the dev error handler escalates.
        if (@getimagesize($file->getPathname()) === false) {
            $this->addFlash('error', sprintf('"%s" is not a readable image (try JPEG, PNG or WebP).', $file->getClientOriginalName()));
            return $back;
        }

        try {
            $this->images->convertAndSave((string) file_get_contents($file->getPathname()), $game, $id);
        } catch (RuntimeException $e) {
            $this->addFlash('error', $e->getMessage());
            return $back;
        }

        $this->addFlash('success', sprintf('Saved image for "%s".', $card->name));

        return $back;
    }
}
