<?php

namespace App\Models;

use CodeIgniter\Model;

class ReplyModel extends Model
{
    protected $table            = 'community_replies';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'array';
    protected $useSoftDeletes   = false;
    protected $protectFields    = true;
    protected $allowedFields    = ['comment_id', 'username', 'content'];

    protected $useTimestamps = false;
}
