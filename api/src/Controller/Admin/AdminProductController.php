<?php declare(strict_types=1);

namespace App\Controller\Admin;

use App\Entity\UnmatchedProduct;
use App\Enum\Game;
use App\Repository\UnmatchedProductRepository;
use App\Service\ProductLinkService;
use Doctrine\ORM\EntityManagerInterface;
use DomainException;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Attribute\MapQueryParameter;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Uid\Uuid;
use function sprintf;
use function trim;

/**
 * Manual linking of shop products the automatcher / stock feed couldn't pair with a card.
 */
#[Route('/admin/products')]
final class AdminProductController extends AbstractController
{
    private const int PAGE_SIZE = 50;
    private const int SEARCH_LIMIT = 30;

    public function __construct(
        private readonly UnmatchedProductRepository $unmatched,
        private readonly ProductLinkService $linker,
        private readonly EntityManagerInterface $entityManager,
    ) {}

    #[Route('', name: 'admin_products', methods: ['GET'])]
    public function index(
        #[MapQueryParameter] ?string $game = null,
        #[MapQueryParameter] int $page = 1,
    ): Response {
        $criteria = $game !== null && $game !== '' ? ['game' => $game] : [];
        $page = max(1, $page);

        return $this->render('admin/products/index.html.twig', [
            'products' => $this->unmatched->findBy($criteria, ['createdAt' => 'ASC'], self::PAGE_SIZE, ($page - 1) * self::PAGE_SIZE),
            'total' => $this->unmatched->count($criteria),
            'page' => $page,
            'pageSize' => self::PAGE_SIZE,
            'game' => $game,
            'games' => Game::cases(),
        ]);
    }

    #[Route('/{id}', name: 'admin_product_show', requirements: ['id' => '\d+'], methods: ['GET'])]
    public function show(
        UnmatchedProduct $product,
        #[MapQueryParameter] ?string $q = null,
        #[MapQueryParameter] ?string $set = null,
    ): Response {
        $q = trim($q ?? $product->name);
        $set = trim($set ?? '');

        return $this->render('admin/products/show.html.twig', [
            'product' => $product,
            'q' => $q,
            'set' => $set,
            'cards' => $this->searchCards($product->game, $q, $set),
        ]);
    }

    #[Route('/{id}/link', name: 'admin_product_link', requirements: ['id' => '\d+'], methods: ['POST'])]
    public function link(UnmatchedProduct $product, Request $request): Response
    {
        if (!$this->isCsrfTokenValid('link-product-' . $product->id, $request->request->getString('_token'))) {
            $this->addFlash('error', 'Session expired, please try again.');
            return $this->redirectToRoute('admin_product_show', ['id' => $product->id]);
        }

        $cardId = $request->request->getString('cardId');
        $finish = trim($request->request->getString('finish'));
        if (!Uuid::isValid($cardId) || $finish === '') {
            $this->addFlash('error', 'Pick a card and a finish.');
            return $this->redirectToRoute('admin_product_show', ['id' => $product->id]);
        }

        $label = sprintf('%s (%s)', $product->name, $product->productId);
        $game = $product->game;

        try {
            $this->linker->link($product, Uuid::fromString($cardId), $finish);
        } catch (DomainException $e) {
            $this->addFlash('error', $e->getMessage());
            return $this->redirectToRoute('admin_product_show', ['id' => $product->id]);
        }

        $this->addFlash('success', sprintf('Linked %s.', $label));

        return $this->redirectToRoute('admin_products', ['game' => $game]);
    }

    /**
     * @return list<\App\ApiResource\Card>
     */
    private function searchCards(string $game, string $q, string $set): array
    {
        $game = Game::tryFrom($game);
        if ($game === null || ($q === '' && $set === '')) {
            return [];
        }

        $qb = $this->entityManager->createQueryBuilder()
            ->select('c', 's')
            ->from($game->cardClass(), 'c')
            ->join('c.set', 's')
            ->orderBy('c.name')
            ->addOrderBy('s.code')
            ->addOrderBy('c.number')
            ->setMaxResults(self::SEARCH_LIMIT);

        if ($q !== '') {
            $qb->andWhere('c.name LIKE :q OR c.number = :number')
                ->setParameter('q', '%' . addcslashes($q, '%_') . '%')
                ->setParameter('number', $q);
        }
        if ($set !== '') {
            $qb->andWhere('s.code = :set')->setParameter('set', $set);
        }

        /** @var list<\App\ApiResource\Card> */
        return $qb->getQuery()->getResult();
    }
}
