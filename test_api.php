<?php
$db = new PDO('mysql:host=localhost;dbname=waqt_db', 'root', '');
$stmt = $db->query('SELECT session_token FROM users LIMIT 1');
$token = $stmt->fetchColumn();

$data = ['history' => [ ['date' => date('Y-m-d'), 'fajr_done' => true, 'dzuhur_done' => false, 'ashar_done' => false, 'maghrib_done' => false, 'isha_done' => false] ]];

$ch = curl_init('http://localhost:8081/api/sync');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Authorization: Bearer ' . $token
]);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));

$response = curl_exec($ch);
$httpcode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

echo "HTTP Code: $httpcode\n";
echo "Response: $response\n";
