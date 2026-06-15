<?php

namespace App\Filters;

use CodeIgniter\Filters\FilterInterface;
use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;
use Config\Services;

class ApiAuthFilter implements FilterInterface
{
    public function before(RequestInterface $request, $arguments = null)
    {
        $authHeader = $request->getHeaderLine('Authorization');
        if (empty($authHeader)) {
            return Services::response()
                ->setStatusCode(401)
                ->setJSON(['status' => 'error', 'message' => 'No authorization header']);
        }

        $parts = explode(' ', $authHeader);
        $token = isset($parts[1]) ? $parts[1] : '';

        if (empty($token)) {
            return Services::response()
                ->setStatusCode(401)
                ->setJSON(['status' => 'error', 'message' => 'Token format is Bearer <token>']);
        }

        $db = \Config\Database::connect();
        $user = $db->table('users')->where('session_token', $token)->get()->getRowArray();

        if (!$user) {
            return Services::response()
                ->setStatusCode(401)
                ->setJSON(['status' => 'error', 'message' => 'Invalid session token']);
        }

        // Store user ID and Username in request headers to bypass PHP 8.2 dynamic property deprecation
        $request->setHeader('X-User-ID', (string) $user['id']);
        $request->setHeader('X-User-Username', $user['username']);
    }

    public function after(RequestInterface $request, ResponseInterface $response, $arguments = null)
    {
        // Do nothing
    }
}
