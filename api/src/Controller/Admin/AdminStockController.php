<?php declare(strict_types=1);

namespace App\Controller\Admin;

use App\Repository\UnmatchedProductRepository;
use App\Service\StockTokenService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Routing\Generator\UrlGeneratorInterface;

/**
 * The stock feed from the web shop: the token it sends (shown, and generated anew here), where it
 * posts to, and what the last update did.
 */
#[Route('/admin/stock')]
final class AdminStockController extends AbstractController
{
    public function __construct(
        private readonly StockTokenService $tokens,
        private readonly UnmatchedProductRepository $unmatched,
    ) {}

    #[Route('', name: 'admin_stock', methods: ['GET'])]
    public function index(): Response
    {
        return $this->render('admin/stock/index.html.twig', [
            'token' => $this->tokens->token(),
            'origin' => $this->tokens->origin(),
            'lastUpdate' => $this->tokens->lastUpdate(),
            'endpoint' => $this->generateUrl('app_stockupdate_update', [], UrlGeneratorInterface::ABSOLUTE_URL),
            'unlinked' => $this->unmatched->count([]),
        ]);
    }

    /**
     * Makes a new token. The old one stops working right away, so the shop needs the new one.
     */
    #[Route('/token', name: 'admin_stock_token', methods: ['POST'])]
    public function generate(Request $request): Response
    {
        if (!$this->isCsrfTokenValid('admin-stock-token', $request->request->getString('_token'))) {
            $this->addFlash('error', 'Session expired, please try again.');

            return $this->redirectToRoute('admin_stock');
        }

        $this->tokens->generate();
        $this->addFlash('success', 'New token made. Give it to the web shop: the old one no longer works.');

        return $this->redirectToRoute('admin_stock');
    }
}
