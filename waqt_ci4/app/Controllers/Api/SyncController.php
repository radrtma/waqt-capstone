<?php

namespace App\Controllers\Api;

use App\Controllers\BaseController;
use App\Models\StreakModel;
use App\Models\HistoryModel;
use App\Models\QadaModel;
use CodeIgniter\API\ResponseTrait;

class SyncController extends BaseController
{
    use ResponseTrait;

    public function sync()
    {
        $userId = $this->request->getHeaderLine('X-User-ID');
        if (!$userId) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Unauthorized'
            ], 401);
        }

        $json = $this->request->getJSON(true);
        $streak = isset($json['streak']) ? $json['streak'] : null;
        $history = isset($json['history']) ? $json['history'] : null;
        $qada = isset($json['qada']) ? $json['qada'] : null;

        $db = \Config\Database::connect();
        $db->transStart();

        // 1. Merge Streak
        if ($streak) {
            $streakModel = new StreakModel();
            $existing = $streakModel->find($userId);
            
            $streakData = [
                'user_id'           => $userId,
                'count'             => isset($streak['count']) ? $streak['count'] : 0,
                'is_frozen'         => (isset($streak['is_frozen']) && $streak['is_frozen']) ? 1 : 0,
                'last_updated_date' => isset($streak['last_updated_date']) ? $streak['last_updated_date'] : ''
            ];

            if ($existing) {
                $streakModel->update($userId, $streakData);
            } else {
                $streakModel->insert($streakData);
            }
        }

        // 2. Merge History
        if ($history && is_array($history)) {
            $historyModel = new HistoryModel();
            foreach ($history as $h) {
                if (!isset($h['date'])) continue;

                $existing = $historyModel->where('user_id', $userId)->where('date', $h['date'])->first();
                $historyData = [
                    'user_id'      => $userId,
                    'date'         => $h['date'],
                    'fajr_done'    => (isset($h['fajr_done']) && $h['fajr_done']) ? 1 : 0,
                    'dzuhur_done'  => (isset($h['dzuhur_done']) && $h['dzuhur_done']) ? 1 : 0,
                    'ashar_done'   => (isset($h['ashar_done']) && $h['ashar_done']) ? 1 : 0,
                    'maghrib_done' => (isset($h['maghrib_done']) && $h['maghrib_done']) ? 1 : 0,
                    'isha_done'    => (isset($h['isha_done']) && $h['isha_done']) ? 1 : 0
                ];

                if ($existing) {
                    $historyModel->where('user_id', $userId)->where('date', $h['date'])->set($historyData)->update();
                } else {
                    $historyModel->insert($historyData);
                }
            }
        }

        // 3. Merge Qada
        if ($qada && is_array($qada)) {
            $qadaModel = new QadaModel();
            foreach ($qada as $q) {
                if (!isset($q['uuid'])) continue;

                $existing = $qadaModel->find($q['uuid']);
                $qadaData = [
                    'uuid'         => $q['uuid'],
                    'user_id'      => $userId,
                    'prayer_name'  => isset($q['prayer_name']) ? $q['prayer_name'] : '',
                    'date_missed'  => isset($q['date_missed']) ? $q['date_missed'] : '',
                    'is_completed' => (isset($q['is_completed']) && $q['is_completed']) ? 1 : 0
                ];

                if ($existing) {
                    $qadaModel->update($q['uuid'], $qadaData);
                } else {
                    $qadaModel->insert($qadaData);
                }
            }
        }

        $db->transComplete();

        if ($db->transStatus() === false) {
            return $this->respond([
                'status'  => 'error',
                'message' => 'Database transaction failed during sync'
            ], 500);
        }

        // Pull Consolidated Data
        $streakModel = new StreakModel();
        $historyModel = new HistoryModel();
        $qadaModel = new QadaModel();

        $dbStreak = $streakModel->find($userId);
        $dbHistory = $historyModel->where('user_id', $userId)->orderBy('date', 'DESC')->limit(30)->findAll();
        $dbQada = $qadaModel->where('user_id', $userId)->findAll();

        $finalStreak = $dbStreak ? [
            'count'             => (int) $dbStreak['count'],
            'is_frozen'         => $dbStreak['is_frozen'] == 1,
            'last_updated_date' => $dbStreak['last_updated_date']
        ] : [
            'count'             => 0,
            'is_frozen'         => false,
            'last_updated_date' => ''
        ];

        $finalHistory = array_map(function($h) {
            return [
                'date'         => $h['date'],
                'fajr_done'    => $h['fajr_done'] == 1,
                'dzuhur_done'  => $h['dzuhur_done'] == 1,
                'ashar_done'   => $h['ashar_done'] == 1,
                'maghrib_done' => $h['maghrib_done'] == 1,
                'isha_done'    => $h['isha_done'] == 1
            ];
        }, $dbHistory);

        $finalQada = array_map(function($q) {
            return [
                'uuid'         => $q['uuid'],
                'prayer_name'  => $q['prayer_name'],
                'date_missed'  => $q['date_missed'],
                'is_completed' => $q['is_completed'] == 1
            ];
        }, $dbQada);

        return $this->respond([
            'status'  => 'success',
            'streak'  => $finalStreak,
            'history' => $finalHistory,
            'qada'    => $finalQada
        ], 200);
    }
}
