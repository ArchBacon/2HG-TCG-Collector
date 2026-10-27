<?php declare(strict_types=1);

namespace App\Controller\Admin;

use App\Enum\CardListType;
use App\Service\AdminStatsService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

final class AdminDashboardController extends AbstractController
{
    #[Route('/admin', name: 'admin_home', methods: ['GET'])]
    public function index(AdminStatsService $stats): Response
    {
        return $this->render('admin/dashboard.html.twig', [
            'totals' => $stats->totals(),
            'periods' => AdminStatsService::PERIODS,
            'topCollected' => $stats->topCards(CardListType::Collection),
            'topWishlisted' => $stats->topCards(CardListType::Wishlist),
            'newUsersPerDay' => $stats->newUsersPerDay(),
            'collectionAddsPerDay' => $stats->collectionAddsPerDay(),
            'collectedPerGame' => $stats->collectedPerGame(),
        ]);
    }
}
