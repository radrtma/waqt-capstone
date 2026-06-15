<?php

namespace App\Models;

use CodeIgniter\Model;

class QadaModel extends Model
{
    protected $table            = 'user_qada';
    protected $primaryKey       = 'uuid';
    protected $useAutoIncrement = false;
    protected $returnType       = 'array';
    protected $useSoftDeletes   = false;
    protected $protectFields    = true;
    protected $allowedFields    = ['uuid', 'user_id', 'prayer_name', 'date_missed', 'is_completed'];

    protected $useTimestamps = false;
}
