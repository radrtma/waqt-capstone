<?php

namespace App\Controllers\Api;

use App\Controllers\BaseController;
use App\Models\PostModel;
use App\Models\CommentModel;
use App\Models\ReplyModel;
use CodeIgniter\API\ResponseTrait;

class PostController extends BaseController
{
    use ResponseTrait;

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
        $limit = $this->request->getVar('limit') ?? 50;
        $limit = (int) $limit;
        $typesStr = $this->request->getVar('types') ?? '';
        
        $postModel = new PostModel();
        
        if (!empty($typesStr)) {
            $types = explode(',', $typesStr);
            $postModel->whereIn('post_type', $types);
        }

        $posts = $postModel->orderBy('created_at', 'DESC')->limit($limit)->findAll();
        
        $formatted = array_map([$this, 'formatPost'], $posts);
        
        return $this->respond($formatted, 200);
    }

    public function show($id = null)
    {
        $postModel = new PostModel();
        $post = $postModel->find($id);

        if (!$post) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Post not found'
            ], 404);
        }

        return $this->respond($this->formatPost($post), 200);
    }

    public function create()
    {
        $username = $this->request->getHeaderLine('X-User-Username');
        if (!$username) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Unauthorized'
            ], 401);
        }

        $json = $this->request->getJSON(true);
        $postType = isset($json['post_type']) ? $json['post_type'] : null;
        $content = isset($json['content']) ? $json['content'] : null;

        if (!$postType || !$content) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Post type and content are required'
            ], 400);
        }

        $imagePaths = isset($json['image_paths']) ? $json['image_paths'] : null;
        if (is_array($imagePaths)) {
            $imagePaths = json_encode($imagePaths);
        }

        $postModel = new PostModel();
        $postData = [
            'post_type'          => $postType,
            'username'           => $username,
            'content'            => $content,
            'mosque_name'        => isset($json['mosque_name']) ? $json['mosque_name'] : null,
            'is_wudu_clean'      => (isset($json['is_wudu_clean']) && $json['is_wudu_clean']) ? 1 : 0,
            'is_ac_working'      => (isset($json['is_ac_working']) && $json['is_ac_working']) ? 1 : 0,
            'is_female_friendly' => (isset($json['is_female_friendly']) && $json['is_female_friendly']) ? 1 : 0,
            'event_name'         => isset($json['event_name']) ? $json['event_name'] : null,
            'event_date'         => isset($json['event_date']) ? $json['event_date'] : null,
            'event_location'     => isset($json['event_location']) ? $json['event_location'] : null,
            'image_paths'        => $imagePaths,
        ];

        $postId = $postModel->insert($postData);
        if ($postId) {
            $newPost = $postModel->find($postId);
            return $this->respond($this->formatPost($newPost), 201);
        }

        return $this->respond([
            'status'  => 'error',
            'message' => 'Failed to insert post'
        ], 500);
    }

    public function update($id = null)
    {
        $username = $this->request->getHeaderLine('X-User-Username');
        if (!$username) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Unauthorized'
            ], 401);
        }

        $postModel = new PostModel();
        $post = $postModel->find($id);

        if (!$post) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Post not found'
            ], 404);
        }

        if ($post['username'] !== $username) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Unauthorized'
            ], 403);
        }

        $json = $this->request->getJSON(true);
        $content = isset($json['content']) ? $json['content'] : $post['content'];
        $imagePaths = isset($json['image_paths']) ? $json['image_paths'] : $post['image_paths'];
        if (is_array($imagePaths)) {
            $imagePaths = json_encode($imagePaths);
        }

        $updateData = [
            'content'            => $content,
            'mosque_name'        => isset($json['mosque_name']) ? $json['mosque_name'] : $post['mosque_name'],
            'is_wudu_clean'      => isset($json['is_wudu_clean']) ? ($json['is_wudu_clean'] ? 1 : 0) : $post['is_wudu_clean'],
            'is_ac_working'      => isset($json['is_ac_working']) ? ($json['is_ac_working'] ? 1 : 0) : $post['is_ac_working'],
            'is_female_friendly' => isset($json['is_female_friendly']) ? ($json['is_female_friendly'] ? 1 : 0) : $post['is_female_friendly'],
            'event_name'         => isset($json['event_name']) ? $json['event_name'] : $post['event_name'],
            'event_date'         => isset($json['event_date']) ? $json['event_date'] : $post['event_date'],
            'event_location'     => isset($json['event_location']) ? $json['event_location'] : $post['event_location'],
            'image_paths'        => $imagePaths,
        ];

        if ($postModel->update($id, $updateData)) {
            return $this->respond([
                'status'  => 'success',
                'message' => 'Post updated'
            ], 200);
        }

        return $this->respond([
            'status'  => 'error',
            'message' => 'Failed to update post'
        ], 500);
    }

    public function delete($id = null)
    {
        $username = $this->request->getHeaderLine('X-User-Username');
        if (!$username) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Unauthorized'
            ], 401);
        }

        $postModel = new PostModel();
        $post = $postModel->find($id);

        if (!$post) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Post not found'
            ], 404);
        }

        if ($post['username'] !== $username) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Unauthorized'
            ], 403);
        }

        if ($postModel->delete($id)) {
            return $this->respond([
                'status'  => 'success',
                'message' => 'Post deleted'
            ], 200);
        }

        return $this->respond([
            'status'  => 'error',
            'message' => 'Failed to delete post'
        ], 500);
    }

    public function react($id = null)
    {
        $json = $this->request->getJSON(true);
        $reactionType = isset($json['reaction_type']) ? $json['reaction_type'] : null;

        if (!in_array($reactionType, ['helpful', 'inspiring', 'useful'])) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Invalid reaction type'
            ], 400);
        }

        $postModel = new PostModel();
        $post = $postModel->find($id);

        if (!$post) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Post not found'
            ], 404);
        }

        $columnName = $reactionType . '_count';
        $postModel->where('id', $id)->increment($columnName, 1);

        // Fetch post again to get updated counts
        $updatedPost = $postModel->find($id);

        return $this->respond([
            'id'              => (int) $updatedPost['id'],
            'helpful_count'   => (int) $updatedPost['helpful_count'],
            'inspiring_count' => (int) $updatedPost['inspiring_count'],
            'useful_count'    => (int) $updatedPost['useful_count']
        ], 200);
    }

    // --- COMMENTS & REPLIES API ---

    public function getComments($postId = null)
    {
        $commentModel = new CommentModel();
        $replyModel = new ReplyModel();

        $comments = $commentModel->where('post_id', $postId)->orderBy('created_at', 'ASC')->findAll();

        if (empty($comments)) {
            return $this->respond([], 200);
        }

        $commentIds = array_column($comments, 'id');
        
        $replies = $replyModel->whereIn('comment_id', $commentIds)->orderBy('created_at', 'ASC')->findAll();

        $repliesMap = [];
        foreach ($replies as $r) {
            $commentId = $r['comment_id'];
            if (!isset($repliesMap[$commentId])) {
                $repliesMap[$commentId] = [];
            }
            $repliesMap[$commentId][] = [
                'id'         => (int) $r['id'],
                'comment_id' => (int) $r['comment_id'],
                'username'   => $r['username'],
                'content'    => $r['content'],
                'created_at' => $r['created_at']
            ];
        }

        $formatted = array_map(function($c) use ($repliesMap) {
            return [
                'id'         => (int) $c['id'],
                'post_id'    => (int) $c['post_id'],
                'username'   => $c['username'],
                'content'    => $c['content'],
                'created_at' => $c['created_at'],
                'replies'    => isset($repliesMap[$c['id']]) ? $repliesMap[$c['id']] : []
            ];
        }, $comments);

        return $this->respond($formatted, 200);
    }

    public function addComment($postId = null)
    {
        $username = $this->request->getHeaderLine('X-User-Username');
        if (!$username) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Unauthorized'
            ], 401);
        }

        $json = $this->request->getJSON(true);
        $content = isset($json['content']) ? trim($json['content']) : null;

        if (!$content) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Comment content is required'
            ], 400);
        }

        $commentModel = new CommentModel();
        $commentData = [
            'post_id'  => $postId,
            'username' => $username,
            'content'  => $content
        ];

        $commentId = $commentModel->insert($commentData);
        if ($commentId) {
            // Increment comment count on post
            $postModel = new PostModel();
            $postModel->where('id', $postId)->increment('comment_count', 1);

            $newComment = $commentModel->find($commentId);

            return $this->respond([
                'status'  => 'success',
                'comment' => [
                    'id'         => (int) $newComment['id'],
                    'post_id'    => (int) $newComment['post_id'],
                    'username'   => $newComment['username'],
                    'content'    => $newComment['content'],
                    'created_at' => $newComment['created_at'],
                    'replies'    => []
                ]
            ], 201);
        }

        return $this->respond([
            'status'  => 'error',
            'message' => 'Failed to add comment'
        ], 500);
    }

    public function deleteComment($id = null)
    {
        $username = $this->request->getHeaderLine('X-User-Username');
        if (!$username) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Unauthorized'
            ], 401);
        }

        $commentModel = new CommentModel();
        $comment = $commentModel->find($id);

        if (!$comment) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Comment not found'
            ], 404);
        }

        if ($comment['username'] !== $username) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Unauthorized to delete this comment'
            ], 403);
        }

        $replyModel = new ReplyModel();
        $replyCount = $replyModel->where('comment_id', $id)->countAllResults();
        $decrementAmount = 1 + $replyCount;

        if ($commentModel->delete($id)) {
            // Decrement comment count on post
            $postModel = new PostModel();
            $post = $postModel->find($comment['post_id']);
            if ($post) {
                $newCount = max(0, $post['comment_count'] - $decrementAmount);
                $postModel->update($comment['post_id'], ['comment_count' => $newCount]);
            }

            return $this->respond([
                'status'  => 'success',
                'message' => 'Comment deleted'
            ], 200);
        }

        return $this->respond([
            'status'  => 'error',
            'message' => 'Failed to delete comment'
        ], 500);
    }

    public function addReply($commentId = null)
    {
        $username = $this->request->getHeaderLine('X-User-Username');
        if (!$username) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Unauthorized'
            ], 401);
        }

        $json = $this->request->getJSON(true);
        $content = isset($json['content']) ? trim($json['content']) : null;

        if (!$content) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Reply content is required'
            ], 400);
        }

        $commentModel = new CommentModel();
        $comment = $commentModel->find($commentId);

        if (!$comment) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Comment not found'
            ], 404);
        }

        $replyModel = new ReplyModel();
        $replyData = [
            'comment_id' => $commentId,
            'username'   => $username,
            'content'    => $content
        ];

        $replyId = $replyModel->insert($replyData);
        if ($replyId) {
            // Increment comment count on post
            $postModel = new PostModel();
            $postModel->where('id', $comment['post_id'])->increment('comment_count', 1);

            $newReply = $replyModel->find($replyId);

            return $this->respond([
                'status' => 'success',
                'reply'  => [
                    'id'         => (int) $newReply['id'],
                    'comment_id' => (int) $newReply['comment_id'],
                    'username'   => $newReply['username'],
                    'content'    => $newReply['content'],
                    'created_at' => $newReply['created_at']
                ]
            ], 201);
        }

        return $this->respond([
            'status'  => 'error',
            'message' => 'Failed to add reply'
        ], 500);
    }

    public function deleteReply($id = null)
    {
        $username = $this->request->getHeaderLine('X-User-Username');
        if (!$username) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Unauthorized'
            ], 401);
        }

        $replyModel = new ReplyModel();
        $reply = $replyModel->find($id);

        if (!$reply) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Reply not found'
            ], 404);
        }

        if ($reply['username'] !== $username) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Unauthorized to delete this reply'
            ], 403);
        }

        // Get comment to find post_id
        $commentModel = new CommentModel();
        $comment = $commentModel->find($reply['comment_id']);

        if ($replyModel->delete($id)) {
            if ($comment) {
                // Decrement comment count on post
                $postModel = new PostModel();
                $post = $postModel->find($comment['post_id']);
                if ($post) {
                    $newCount = max(0, $post['comment_count'] - 1);
                    $postModel->update($comment['post_id'], ['comment_count' => $newCount]);
                }
            }

            return $this->respond([
                'status'  => 'success',
                'message' => 'Reply deleted'
            ], 200);
        }

        return $this->respond([
            'status'  => 'error',
            'message' => 'Failed to delete reply'
        ], 500);
    }

    // --- FILE UPLOAD ---

    public function upload()
    {
        $img = $this->request->getFile('image');
        if (!$img || !$img->isValid()) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'No file uploaded'
            ], 400);
        }

        $newName = $img->getRandomName();
        $uploadDir = FCPATH . 'uploads/posts';
        
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0777, true);
        }

        $img->move($uploadDir, $newName);

        return $this->respond([
            'status' => 'success',
            'path'   => 'uploads/posts/' . $newName
        ], 200);
    }
}
