<?php

namespace App\Controllers;

class Auth extends BaseController
{
    protected $session;

    public function __construct()
    {
        $this->session = session();
    }

    public function login()
    {
        if ($this->session->get('logged_in')) {
            return redirect()->to('/');
        }
        return view('auth/login');
    }

    public function loginPost()
    {
        $username = $this->request->getPost('username');
        $password = $this->request->getPost('password');
        $mode = $this->request->getPost('auth_mode'); // 'login' or 'register'

        if (empty($username) || empty($password)) {
            $this->session->setFlashdata('error', 'Username dan password tidak boleh kosong.');
            return redirect()->back();
        }

        $userModel = new \App\Models\UserModel();
        $username = trim($username);

        try {
            if ($mode === 'register') {
                $confirmPassword = $this->request->getPost('confirm_password');
                if ($password !== $confirmPassword) {
                    $this->session->setFlashdata('error', 'Konfirmasi password tidak cocok.');
                    return redirect()->back()->withInput();
                }

                // Check if username already exists
                if ($userModel->where('username', $username)->first()) {
                    $this->session->setFlashdata('error', 'Username sudah terdaftar.');
                    return redirect()->back()->withInput();
                }

                $passwordHash = password_hash($password, PASSWORD_BCRYPT);
                $sessionToken = bin2hex(random_bytes(16));

                $userData = [
                    'username'      => $username,
                    'password_hash' => $passwordHash,
                    'session_token' => $sessionToken
                ];

                if ($userModel->insert($userData)) {
                    $this->session->set([
                        'logged_in'     => true,
                        'username'      => $username,
                        'session_token' => $sessionToken
                    ]);
                    return redirect()->to('/');
                }

                $this->session->setFlashdata('error', 'Registrasi gagal. Silakan coba lagi.');
                return redirect()->back()->withInput();

            } else {
                // Login Mode
                $user = $userModel->where('username', $username)->first();

                if (!$user || !password_verify($password, $user['password_hash'])) {
                    $this->session->setFlashdata('error', 'Username atau password salah.');
                    return redirect()->back()->withInput();
                }

                $sessionToken = $user['session_token'];
                if (empty($sessionToken)) {
                    $sessionToken = bin2hex(random_bytes(16));
                    $userModel->update($user['id'], ['session_token' => $sessionToken]);
                }

                $this->session->set([
                    'logged_in'     => true,
                    'username'      => $username,
                    'session_token' => $sessionToken
                ]);

                return redirect()->to('/');
            }

        } catch (\Exception $e) {
            $this->session->setFlashdata('error', 'Gagal memproses autentikasi: ' . $e->getMessage());
            return redirect()->back()->withInput();
        }
    }

    public function logout()
    {
        $this->session->destroy();
        return redirect()->to('/login');
    }
}
