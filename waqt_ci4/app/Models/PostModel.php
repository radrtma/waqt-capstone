<?php

namespace App\Models;

use CodeIgniter\Model;

class PostModel extends Model
{
    protected $table            = 'community_posts';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'array';
    protected $useSoftDeletes   = false;
    protected $protectFields    = true;
    protected $allowedFields    = [
        'post_type', 'username', 'content', 'mosque_name',
        'is_wudu_clean', 'is_ac_working', 'is_female_friendly',
        'helpful_count', 'inspiring_count', 'useful_count',
        'event_name', 'event_date', 'event_location',
        'comment_count', 'image_paths'
    ];

    protected $useTimestamps = false;
}
