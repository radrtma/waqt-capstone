<?php

namespace App\Models;

use CodeIgniter\Model;

class StreakModel extends Model
{
    protected $table            = 'user_streaks';
    protected $primaryKey       = 'user_id';
    protected $useAutoIncrement = false;
    protected $returnType       = 'array';
    protected $useSoftDeletes   = false;
    protected $protectFields    = true;
    protected $allowedFields    = ['user_id', 'count', 'is_frozen', 'last_updated_date'];

    protected $useTimestamps = false;
}
