<?php declare(strict_types=1);

namespace App\Controller\Admin;

use LogicException;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Authentication\AuthenticationUtils;

final class AdminSecurityController extends AbstractController
{
    #[Route('/admin', name: 'admin_home', methods: ['GET'])]
    public function home(): Response
    {
        return $this->redirectToRoute('admin_products');
    }

    /** Renders the form; the POST is handled by the admin firewall's form_login. */
    #[Route('/admin/login', name: 'admin_login', methods: ['GET', 'POST'])]
    public function login(AuthenticationUtils $authenticationUtils): Response
    {
        if ($this->getUser() !== null) {
            return $this->redirectToRoute('admin_products');
        }

        return $this->render('admin/login.html.twig', [
            'lastUsername' => $authenticationUtils->getLastUsername(),
            'error' => $authenticationUtils->getLastAuthenticationError(),
        ]);
    }

    #[Route('/admin/logout', name: 'admin_logout', methods: ['GET'])]
    public function logout(): never
    {
        throw new LogicException('Intercepted by the admin firewall\'s logout.');
    }
}
