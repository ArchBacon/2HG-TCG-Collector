<?php declare(strict_types=1);

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

final class PageController extends AbstractController
{
    #[Route('/', name: 'app_home', methods: ['GET'])]
    public function home(): Response
    {
        return $this->render('pages/home.html.twig');
    }

    #[Route('/search', name: 'app_search', methods: ['GET'])]
    public function search(): Response
    {
        return $this->render('pages/search.html.twig');
    }
}
