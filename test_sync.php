<?php
$token = 'test_token_123'; // Assuming a token exists or we just see if we get 401 instead of 500

// We first need a valid token. Let's just create a test request with an invalid token first to see if it responds 401 instead of crashing.
// Wait, better to get the token of User 1 directly from MySQL!

$conn = new mysqli("localhost", "root", "", "waqt_db");
$result = $conn->query("SELECT session_token FROM users LIMIT 1");
$row = $result->fetch_assoc();
$token = $row['session_token'];

$payload = [
    "streak" => [
        "count" => 5,
        "is_frozen" => 1,
        "last_updated_date" => date('Y-m-d')
    ],
    "history" => [
        [
            "date" => date('Y-m-d'),
            "fajr_done" => 1,
            "dzuhur_done" => 0,
            "ashar_done" => 1,
            "maghrib_done" => 0,
            "isha_done" => 0
        ]
    ],
    "qada" => []
];

$ch = curl_init('http://127.0.0.1:8080/api/sync');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Authorization: Bearer ' . $token
]);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));

$response = curl_exec($ch);
$httpcode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $httpcode\n";
echo "Response: $response\n";
