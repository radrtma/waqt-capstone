<?php

namespace App\Controllers;

use App\Models\PostModel;
use App\Models\CommentModel;
use App\Models\ReplyModel;

class Community extends BaseController
{
    protected $session;

    public function __construct()
    {
        $this->session = session();
    }

    private function formatPost($post)
    {
        $imagePaths = json_decode($post['image_paths'] ?? '', true);
        if (!is_array($imagePaths)) {
            if ($post['image_paths'] && !str_starts_with($post['image_paths'], '[')) {
                $imagePaths = array_filter(array_map('trim', explode(',', $post['image_paths'])));
            } else {
                $imagePaths = [];
            }
        }

        return [
            'id'                 => (int) $post['id'],
            'post_type'          => $post['post_type'],
            'username'           => $post['username'],
            'content'            => $post['content'],
            'mosque_name'        => $post['mosque_name'],
            'is_wudu_clean'      => $post['is_wudu_clean'] == 1,
            'is_ac_working'      => $post['is_ac_working'] == 1,
            'is_female_friendly' => $post['is_female_friendly'] == 1,
            'helpful_count'      => (int) $post['helpful_count'],
            'inspiring_count'    => (int) $post['inspiring_count'],
            'useful_count'       => (int) $post['useful_count'],
            'event_name'         => $post['event_name'],
            'event_date'         => $post['event_date'],
            'event_location'     => $post['event_location'],
            'comment_count'      => (int) $post['comment_count'],
            'image_paths'        => $imagePaths,
            'created_at'         => $post['created_at']
        ];
    }

    public function index()
    {
        if (!$this->session->get('logged_in')) {
            return redirect()->to('/login');
        }

        $posts = [];
        try {
            $postModel = new PostModel();
            $allPosts = $postModel->orderBy('created_at', 'DESC')->findAll();
            $posts = array_map([$this, 'formatPost'], $allPosts);
        } catch (\Exception $e) {
            // Fallback
        }

        // Keaktifan Komunitas (Strictly based on MySQL Database)
        $activeMembers = 0;
        $trackedPrayersCount = 0;
        $mosqueReviewsCount = 0;

        try {
            $userModel = new \App\Models\UserModel();
            $activeMembers = (int)$userModel->countAllResults();
        } catch (\Exception $e) {}

        try {
            $historyModel = new \App\Models\HistoryModel();
            $builder = $historyModel->builder();
            $builder->selectSum('fajr_done');
            $builder->selectSum('dzuhur_done');
            $builder->selectSum('ashar_done');
            $builder->selectSum('maghrib_done');
            $builder->selectSum('isha_done');
            $sumRes = $builder->get()->getRowArray();
            $trackedPrayersCount = (int)($sumRes['fajr_done'] ?? 0) + 
                                  (int)($sumRes['dzuhur_done'] ?? 0) + 
                                  (int)($sumRes['ashar_done'] ?? 0) + 
                                  (int)($sumRes['maghrib_done'] ?? 0) + 
                                  (int)($sumRes['isha_done'] ?? 0);
        } catch (\Exception $e) {}

        try {
            $postModel = new PostModel();
            $mosqueReviewsCount = (int)$postModel->where('post_type', 'mosque')->countAllResults();
        } catch (\Exception $e) {}

        $data = [
            'activeTab'           => 'community',
            'username'            => $this->session->get('username'),
            'session_token'       => $this->session->get('session_token'),
            'posts'               => $posts,
            'activeMembers'       => $activeMembers,
            'trackedPrayersCount' => $trackedPrayersCount,
            'mosqueReviewsCount'  => $mosqueReviewsCount,
            'recommendedMosques'  => $this->getMosqueRecommendations(2),
            'dailyReflection'     => $this->getDailyReflection()
        ];

        return view('tabs/community', $data);
    }

    public function createPost()
    {
        if (!$this->session->get('logged_in')) {
            return redirect()->to('/login');
        }

        $data = [
            'activeTab'     => 'community',
            'username'      => $this->session->get('username'),
            'session_token' => $this->session->get('session_token')
        ];

        return view('tabs/create_post', $data);
    }

    public function submitPost()
    {
        if (!$this->session->get('logged_in')) {
            return redirect()->to('/login');
        }

        $postType = $this->request->getPost('post_type');
        $content = $this->request->getPost('content');
        $mosqueName = $this->request->getPost('mosque_name');
        
        $isWuduClean = $this->request->getPost('is_wudu_clean') ? true : false;
        $isAcWorking = $this->request->getPost('is_ac_working') ? true : false;
        $isFemaleFriendly = $this->request->getPost('is_female_friendly') ? true : false;

        $eventName = $this->request->getPost('event_name');
        $eventDate = $this->request->getPost('event_date');
        $eventLocation = $this->request->getPost('event_location');

        if (empty($content)) {
            $this->session->setFlashdata('error', 'Isi postingan tidak boleh kosong.');
            return redirect()->back();
        }

        // Process multiple image files
        $files = $this->request->getFiles();
        $imagePaths = [];
        if (isset($files['images'])) {
            foreach ($files['images'] as $file) {
                if ($file->isValid() && !$file->hasMoved()) {
                    $newName = $file->getRandomName();
                    $uploadDir = FCPATH . 'uploads/posts';
                    if (!is_dir($uploadDir)) {
                        mkdir($uploadDir, 0777, true);
                    }
                    $file->move($uploadDir, $newName);
                    $imagePaths[] = 'uploads/posts/' . $newName;
                }
            }
        }

        try {
            $postModel = new PostModel();
            $postData = [
                'post_type'          => $postType,
                'username'           => $this->session->get('username'),
                'content'            => $content,
                'mosque_name'        => $postType === 'mosque' ? $mosqueName : null,
                'is_wudu_clean'      => $isWuduClean ? 1 : 0,
                'is_ac_working'      => $isAcWorking ? 1 : 0,
                'is_female_friendly' => $isFemaleFriendly ? 1 : 0,
                'event_name'         => $postType === 'event' ? $eventName : null,
                'event_date'         => $postType === 'event' ? $eventDate : null,
                'event_location'     => $postType === 'event' ? $eventLocation : null,
                'image_paths'        => json_encode($imagePaths)
            ];

            if ($postModel->insert($postData)) {
                return redirect()->to('/community');
            }

            $this->session->setFlashdata('error', 'Gagal memposting ke komunitas.');
            return redirect()->back()->withInput();
        } catch (\Exception $e) {
            $this->session->setFlashdata('error', 'Gagal terhubung ke database: ' . $e->getMessage());
            return redirect()->back()->withInput();
        }
    }

    public function viewPost($id)
    {
        if (!$this->session->get('logged_in')) {
            return redirect()->to('/login');
        }

        $post = null;
        $comments = [];

        try {
            $postModel = new PostModel();
            $dbPost = $postModel->find($id);
            if ($dbPost) {
                $post = $this->formatPost($dbPost);
            }

            if ($post) {
                $commentModel = new CommentModel();
                $replyModel = new ReplyModel();

                $dbComments = $commentModel->where('post_id', $id)->orderBy('created_at', 'ASC')->findAll();
                
                if (!empty($dbComments)) {
                    $commentIds = array_column($dbComments, 'id');
                    $dbReplies = $replyModel->whereIn('comment_id', $commentIds)->orderBy('created_at', 'ASC')->findAll();
                    
                    $repliesMap = [];
                    foreach ($dbReplies as $r) {
                        $repliesMap[$r['comment_id']][] = $r;
                    }
                    
                    $comments = array_map(function($c) use ($repliesMap) {
                        return [
                            'id'         => (int) $c['id'],
                            'post_id'    => (int) $c['post_id'],
                            'username'   => $c['username'],
                            'content'    => $c['content'],
                            'created_at' => $c['created_at'],
                            'replies'    => isset($repliesMap[$c['id']]) ? $repliesMap[$c['id']] : []
                        ];
                    }, $dbComments);
                }
            }
        } catch (\Exception $e) {
            // Fallback
        }

        if (!$post) {
            throw \CodeIgniter\Exceptions\PageNotFoundException::forPageNotFound("Postingan tidak ditemukan.");
        }

        $data = [
            'activeTab'     => 'community',
            'username'      => $this->session->get('username'),
            'session_token' => $this->session->get('session_token'),
            'post'          => $post,
            'comments'      => $comments
        ];

        return view('tabs/view_post', $data);
    }

    public function addComment()
    {
        if (!$this->session->get('logged_in')) {
            return $this->response->setStatusCode(401)->setJSON(['status' => 'error', 'message' => 'Unauthorized']);
        }

        $postId = $this->request->getPost('post_id');
        $content = $this->request->getPost('comment_text');

        if (empty($postId) || empty($content)) {
            return $this->response->setJSON(['status' => 'error', 'message' => 'Data tidak lengkap.']);
        }

        try {
            $commentModel = new CommentModel();
            $commentData = [
                'post_id'  => $postId,
                'username' => $this->session->get('username'),
                'content'  => $content
            ];

            $commentId = $commentModel->insert($commentData);
            if ($commentId) {
                // Increment comment count on post
                $postModel = new PostModel();
                $postModel->where('id', $postId)->increment('comment_count', 1);

                $newComment = $commentModel->find($commentId);

                return $this->response->setJSON([
                    'status'  => 'success',
                    'comment' => [
                        'id'         => (int) $newComment['id'],
                        'post_id'    => (int) $newComment['post_id'],
                        'username'   => $newComment['username'],
                        'content'    => $newComment['content'],
                        'created_at' => $newComment['created_at'],
                        'replies'    => []
                    ]
                ]);
            }

            return $this->response->setJSON(['status' => 'error', 'message' => 'Gagal menambahkan komentar.']);
        } catch (\Exception $e) {
            return $this->response->setJSON(['status' => 'error', 'message' => 'Gagal terhubung ke database.']);
        }
    }

    public function deleteComment()
    {
        if (!$this->session->get('logged_in')) {
            return $this->response->setStatusCode(401)->setJSON(['status' => 'error', 'message' => 'Unauthorized']);
        }

        $commentId = $this->request->getPost('comment_id');

        if (empty($commentId)) {
            return $this->response->setJSON(['status' => 'error', 'message' => 'Data tidak lengkap.']);
        }

        try {
            $commentModel = new CommentModel();
            $comment = $commentModel->find($commentId);

            if (!$comment) {
                return $this->response->setJSON(['status' => 'error', 'message' => 'Komentar tidak ditemukan.']);
            }

            // Check if user is owner
            if ($comment['username'] !== $this->session->get('username')) {
                return $this->response->setStatusCode(403)->setJSON(['status' => 'error', 'message' => 'Unauthorized']);
            }

            $replyModel = new ReplyModel();
            $replyCount = $replyModel->where('comment_id', $commentId)->countAllResults();
            $decrementAmount = 1 + $replyCount;

            if ($commentModel->delete($commentId)) {
                $postModel = new PostModel();
                $post = $postModel->find($comment['post_id']);
                if ($post) {
                    $newCount = max(0, $post['comment_count'] - $decrementAmount);
                    $postModel->update($comment['post_id'], ['comment_count' => $newCount]);
                }
                return $this->response->setJSON(['status' => 'success']);
            }

            return $this->response->setJSON(['status' => 'error', 'message' => 'Gagal menghapus komentar.']);
        } catch (\Exception $e) {
            return $this->response->setJSON(['status' => 'error', 'message' => 'Gagal terhubung ke database.']);
        }
    }

    public function addReply()
    {
        if (!$this->session->get('logged_in')) {
            return $this->response->setStatusCode(401)->setJSON(['status' => 'error', 'message' => 'Unauthorized']);
        }

        $commentId = $this->request->getPost('comment_id');
        $content = $this->request->getPost('reply_text');

        if (empty($commentId) || empty($content)) {
            return $this->response->setJSON(['status' => 'error', 'message' => 'Data tidak lengkap.']);
        }

        try {
            $commentModel = new CommentModel();
            $comment = $commentModel->find($commentId);

            if (!$comment) {
                return $this->response->setJSON(['status' => 'error', 'message' => 'Komentar tidak ditemukan.']);
            }

            $replyModel = new ReplyModel();
            $replyData = [
                'comment_id' => $commentId,
                'username'   => $this->session->get('username'),
                'content'    => $content
            ];

            $replyId = $replyModel->insert($replyData);
            if ($replyId) {
                // Increment comment count on post
                $postModel = new PostModel();
                $postModel->where('id', $comment['post_id'])->increment('comment_count', 1);

                $newReply = $replyModel->find($replyId);

                return $this->response->setJSON([
                    'status' => 'success',
                    'reply'  => [
                        'id'         => (int) $newReply['id'],
                        'comment_id' => (int) $newReply['comment_id'],
                        'username'   => $newReply['username'],
                        'content'    => $newReply['content'],
                        'created_at' => $newReply['created_at']
                    ]
                ]);
            }

            return $this->response->setJSON(['status' => 'error', 'message' => 'Gagal menambahkan balasan.']);
        } catch (\Exception $e) {
            return $this->response->setJSON(['status' => 'error', 'message' => 'Gagal terhubung ke database.']);
        }
    }

    public function deleteReply()
    {
        if (!$this->session->get('logged_in')) {
            return $this->response->setStatusCode(401)->setJSON(['status' => 'error', 'message' => 'Unauthorized']);
        }

        $replyId = $this->request->getPost('reply_id');

        if (empty($replyId)) {
            return $this->response->setJSON(['status' => 'error', 'message' => 'Data tidak lengkap.']);
        }

        try {
            $replyModel = new ReplyModel();
            $reply = $replyModel->find($replyId);

            if (!$reply) {
                return $this->response->setJSON(['status' => 'error', 'message' => 'Balasan tidak ditemukan.']);
            }

            if ($reply['username'] !== $this->session->get('username')) {
                return $this->response->setStatusCode(403)->setJSON(['status' => 'error', 'message' => 'Unauthorized']);
            }

            $commentModel = new CommentModel();
            $comment = $commentModel->find($reply['comment_id']);

            if ($replyModel->delete($replyId)) {
                if ($comment) {
                    $postModel = new PostModel();
                    $post = $postModel->find($comment['post_id']);
                    if ($post) {
                        $newCount = max(0, $post['comment_count'] - 1);
                        $postModel->update($comment['post_id'], ['comment_count' => $newCount]);
                    }
                }
                return $this->response->setJSON(['status' => 'success']);
            }

            return $this->response->setJSON(['status' => 'error', 'message' => 'Gagal menghapus balasan.']);
        } catch (\Exception $e) {
            return $this->response->setJSON(['status' => 'error', 'message' => 'Gagal terhubung ke database.']);
        }
    }

    public function editPost($id)
    {
        if (!$this->session->get('logged_in')) {
            return redirect()->to('/login');
        }

        $post = null;
        try {
            $postModel = new PostModel();
            $dbPost = $postModel->find($id);
            if ($dbPost) {
                $post = $this->formatPost($dbPost);
            }
        } catch (\Exception $e) {
            // Error handling
        }

        if (!$post) {
            throw \CodeIgniter\Exceptions\PageNotFoundException::forPageNotFound("Postingan tidak ditemukan.");
        }

        // Security check: only author can edit
        if ($post['username'] !== $this->session->get('username')) {
            return redirect()->to('/community')->with('error', 'Anda tidak memiliki akses untuk mengedit postingan ini.');
        }

        $data = [
            'activeTab'     => 'community',
            'username'      => $this->session->get('username'),
            'session_token' => $this->session->get('session_token'),
            'post'          => $post
        ];

        return view('tabs/edit_post', $data);
    }

    public function updatePost($id)
    {
        if (!$this->session->get('logged_in')) {
            return redirect()->to('/login');
        }

        $content = $this->request->getPost('content');
        $mosqueName = $this->request->getPost('mosque_name');
        
        $isWuduClean = $this->request->getPost('is_wudu_clean') ? true : false;
        $isAcWorking = $this->request->getPost('is_ac_working') ? true : false;
        $isFemaleFriendly = $this->request->getPost('is_female_friendly') ? true : false;

        $eventName = $this->request->getPost('event_name');
        $eventDate = $this->request->getPost('event_date');
        $eventLocation = $this->request->getPost('event_location');

        if (empty($content)) {
            $this->session->setFlashdata('error', 'Isi postingan tidak boleh kosong.');
            return redirect()->back();
        }

        // Process new images if uploaded
        $files = $this->request->getFiles();
        $imagePaths = null;
        $hasNewImages = false;

        if (isset($files['images'])) {
            $uploadedPaths = [];
            foreach ($files['images'] as $file) {
                if ($file->isValid() && !$file->hasMoved()) {
                    $newName = $file->getRandomName();
                    $uploadDir = FCPATH . 'uploads/posts';
                    if (!is_dir($uploadDir)) {
                        mkdir($uploadDir, 0777, true);
                    }
                    $file->move($uploadDir, $newName);
                    $uploadedPaths[] = 'uploads/posts/' . $newName;
                    $hasNewImages = true;
                }
            }
            if ($hasNewImages) {
                $imagePaths = json_encode($uploadedPaths);
            }
        }

        // If no new images uploaded, use the existing ones passed from the form
        if (!$hasNewImages) {
            $existingStr = $this->request->getPost('existing_image_paths');
            if (!empty($existingStr)) {
                $imagePaths = $existingStr;
            }
        }

        try {
            $postModel = new PostModel();
            $post = $postModel->find($id);

            if (!$post) {
                throw \CodeIgniter\Exceptions\PageNotFoundException::forPageNotFound("Postingan tidak ditemukan.");
            }

            if ($post['username'] !== $this->session->get('username')) {
                return redirect()->to('/community')->with('error', 'Anda tidak memiliki akses untuk mengedit postingan ini.');
            }

            $updateData = [
                'content'            => $content,
                'mosque_name'        => $mosqueName,
                'is_wudu_clean'      => $isWuduClean ? 1 : 0,
                'is_ac_working'      => $isAcWorking ? 1 : 0,
                'is_female_friendly' => $isFemaleFriendly ? 1 : 0,
                'event_name'         => $eventName,
                'event_date'         => $eventDate,
                'event_location'     => $eventLocation,
                'image_paths'        => $imagePaths
            ];

            if ($postModel->update($id, $updateData)) {
                $this->session->setFlashdata('success', 'Postingan berhasil diperbarui.');
                return redirect()->to('/profile');
            }

            $this->session->setFlashdata('error', 'Gagal memperbarui postingan.');
            return redirect()->back();
        } catch (\Exception $e) {
            $this->session->setFlashdata('error', 'Gagal terhubung ke database: ' . $e->getMessage());
            return redirect()->back();
        }
    }

    public function deletePost($id)
    {
        if (!$this->session->get('logged_in')) {
            return redirect()->to('/login');
        }

        try {
            $postModel = new PostModel();
            $post = $postModel->find($id);

            if (!$post) {
                throw \CodeIgniter\Exceptions\PageNotFoundException::forPageNotFound("Postingan tidak ditemukan.");
            }

            if ($post['username'] !== $this->session->get('username')) {
                return redirect()->to('/profile')->with('error', 'Anda tidak memiliki akses untuk menghapus postingan ini.');
            }

            if ($postModel->delete($id)) {
                $this->session->setFlashdata('success', 'Postingan berhasil dihapus.');
            } else {
                $this->session->setFlashdata('error', 'Gagal menghapus postingan.');
            }
        } catch (\Exception $e) {
            $this->session->setFlashdata('error', 'Gagal terhubung ke database.');
        }

        return redirect()->to('/profile');
    }
}
