<?php

namespace App\Controllers\Api;

use App\Controllers\BaseController;
use App\Models\UserModel;
use CodeIgniter\API\ResponseTrait;

class AuthController extends BaseController
{
    use ResponseTrait;

    public function register()
    {
        $json = $this->request->getJSON(true);
        $username = isset($json['username']) ? trim($json['username']) : null;
        $password = isset($json['password']) ? trim($json['password']) : null;

        if (!$username || !$password) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Username and password required'
            ], 400);
        }

        $userModel = new UserModel();
        
        // Check if username already exists
        if ($userModel->where('username', $username)->first()) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Username already exists'
            ], 400);
        }

        $passwordHash = password_hash($password, PASSWORD_BCRYPT);
        $sessionToken = bin2hex(random_bytes(16));

        $userData = [
            'username'      => $username,
            'password_hash' => $passwordHash,
            'session_token' => $sessionToken
        ];

        if ($userModel->insert($userData)) {
            return $this->respond([
                'status'   => 'success',
                'token'    => $sessionToken,
                'username' => $username
            ], 201);
        }

        return $this->respond([
            'status'  => 'error',
            'message' => 'Registration failed'
        ], 500);
    }

    public function login()
    {
        $json = $this->request->getJSON(true);
        $username = isset($json['username']) ? trim($json['username']) : null;
        $password = isset($json['password']) ? trim($json['password']) : null;

        if (!$username || !$password) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Username and password required'
            ], 400);
        }

        $userModel = new UserModel();
        $user = $userModel->where('username', $username)->first();

        if (!$user || !password_verify($password, $user['password_hash'])) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Invalid credentials'
            ], 401);
        }

        $sessionToken = bin2hex(random_bytes(16));
        $userModel->update($user['id'], ['session_token' => $sessionToken]);

        return $this->respond([
            'status'   => 'success',
            'token'    => $sessionToken,
            'username' => $username
        ], 200);
    }

    public function updateProfile()
    {
        $userId = $this->request->getHeaderLine('X-User-ID');
        if (!$userId) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Unauthorized'
            ], 401);
        }

        $json = $this->request->getJSON(true);
        $username = isset($json['username']) ? trim($json['username']) : null;
        $password = isset($json['password']) ? trim($json['password']) : null;

        if (!$username && !$password) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Username or password required to update'
            ], 400);
        }

        $userModel = new UserModel();
        $updateData = [];

        if ($username) {
            // Check if username already exists for another user
            $existing = $userModel->where('username', $username)->first();
            if ($existing && $existing['id'] != $userId) {
                return $this->respond([
                    'status'  => 'error',
                    'message' => 'Username already exists'
                ], 400);
            }
            $updateData['username'] = $username;
        }

        if ($password) {
            $updateData['password_hash'] = password_hash($password, PASSWORD_BCRYPT);
        }

        if ($userModel->update($userId, $updateData)) {
            $response = [
                'status'  => 'success',
                'message' => 'Profile updated successfully'
            ];
            if ($username) {
                $response['username'] = $username;
            }
            return $this->respond($response, 200);
        }

        return $this->respond([
            'status'  => 'error',
            'message' => 'Failed to update profile'
        ], 500);
    }
}
