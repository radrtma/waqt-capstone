<?php
$conn = new mysqli("localhost", "root", "", "waqt_db");
$result = $conn->query("SELECT session_token FROM users WHERE username = 'Ridhwan' LIMIT 1");
$row = $result->fetch_assoc();
$token = $row['session_token'];

$ch = curl_init('http://127.0.0.1:8080/api/sync');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Authorization: Bearer ' . $token
]);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode(["history" => []])); // empty payload to just fetch

$response = curl_exec($ch);
echo "Spring Boot Response:\n$response\n";
