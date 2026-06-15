<?php

namespace App\Controllers;

class Home extends BaseController
{
    protected $session;

    public function __construct()
    {
        $this->session = session();
    }

    public function index()
    {
        if (!$this->session->get('logged_in')) {
            return redirect()->to('/login');
        }

        $recentPosts = [];
        
        try {
            $postModel = new \App\Models\PostModel();
            $allPosts = $postModel->orderBy('created_at', 'DESC')->limit(10)->findAll();
            
            $formatted = array_map(function($p) {
                $imagePaths = json_decode($p['image_paths'] ?? '', true);
                if (!is_array($imagePaths)) {
                    if ($p['image_paths'] && !str_starts_with($p['image_paths'], '[')) {
                        $imagePaths = array_filter(array_map('trim', explode(',', $p['image_paths'])));
                    } else {
                        $imagePaths = [];
                    }
                }
                return array_merge($p, [
                    'is_wudu_clean'      => $p['is_wudu_clean'] == 1,
                    'is_ac_working'      => $p['is_ac_working'] == 1,
                    'is_female_friendly' => $p['is_female_friendly'] == 1,
                    'image_paths'        => $imagePaths
                ]);
            }, $allPosts);

            // Prioritize 'event', then others
            $events = array_filter($formatted, function($p) {
                return isset($p['post_type']) && $p['post_type'] === 'event';
            });
            $others = array_filter($formatted, function($p) {
                return isset($p['post_type']) && $p['post_type'] !== 'event';
            });
            
            $recentPosts = array_merge($events, $others);
            $recentPosts = array_slice($recentPosts, 0, 3);
        } catch (\Exception $e) {
            // Fallback to empty recent posts
        }

        $data = [
            'activeTab' => 'dashboard',
            'username' => $this->session->get('username'),
            'session_token' => $this->session->get('session_token'),
            'recentPosts' => $recentPosts,
            'recommendedMosques' => $this->getMosqueRecommendations(2),
            'dailyReflection' => $this->getDailyReflection()
        ];

        return view('tabs/dashboard', $data);
    }

    public function prayer()
    {
        if (!$this->session->get('logged_in')) {
            return redirect()->to('/login');
        }

        $data = [
            'activeTab' => 'schedule',
            'username' => $this->session->get('username'),
            'session_token' => $this->session->get('session_token')
        ];

        return view('tabs/prayer', $data);
    }

    public function history()
    {
        if (!$this->session->get('logged_in')) {
            return redirect()->to('/login');
        }

        $data = [
            'activeTab' => 'history',
            'username' => $this->session->get('username'),
            'session_token' => $this->session->get('session_token')
        ];

        return view('tabs/history', $data);
    }

    public function profile()
    {
        if (!$this->session->get('logged_in')) {
            return redirect()->to('/login');
        }

        $posts = [];
        
        try {
            $postModel = new \App\Models\PostModel();
            $currentUsername = $this->session->get('username');
            $allPosts = $postModel->where('username', $currentUsername)->orderBy('created_at', 'DESC')->findAll();
            
            $posts = array_map(function($p) {
                $imagePaths = json_decode($p['image_paths'] ?? '', true);
                if (!is_array($imagePaths)) {
                    if ($p['image_paths'] && !str_starts_with($p['image_paths'], '[')) {
                        $imagePaths = array_filter(array_map('trim', explode(',', $p['image_paths'])));
                    } else {
                        $imagePaths = [];
                    }
                }
                return array_merge($p, [
                    'is_wudu_clean'      => $p['is_wudu_clean'] == 1,
                    'is_ac_working'      => $p['is_ac_working'] == 1,
                    'is_female_friendly' => $p['is_female_friendly'] == 1,
                    'image_paths'        => $imagePaths
                ]);
            }, $allPosts);
        } catch (\Exception $e) {
            // Fallback to empty posts
        }

        $data = [
            'activeTab' => 'profile',
            'username' => $this->session->get('username'),
            'session_token' => $this->session->get('session_token'),
            'posts' => $posts
        ];

        return view('tabs/profile', $data);
    }
}
