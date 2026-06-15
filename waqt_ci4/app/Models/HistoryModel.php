<?php

namespace App\Models;

use CodeIgniter\Model;

class HistoryModel extends Model
{
    protected $table            = 'user_history';
    protected $primaryKey       = 'user_id';
    protected $useAutoIncrement = false;
    protected $returnType       = 'array';
    protected $useSoftDeletes   = false;
    protected $protectFields    = true;
    protected $allowedFields    = [
        'user_id', 'date', 'fajr_done', 'dzuhur_done',
        'ashar_done', 'maghrib_done', 'isha_done'
    ];

    protected $useTimestamps = false;
}
