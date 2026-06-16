<?php
$db = new PDO('mysql:host=localhost;dbname=waqt_db', 'root', '');
$stmt = $db->query('SELECT session_token FROM users LIMIT 1');
$token = $stmt->fetchColumn();

// Check if user_history actually updated
$stmt = $db->query("SELECT * FROM user_history WHERE date = '2026-06-16'");
$row = $stmt->fetch(PDO::FETCH_ASSOC);
echo "DB State: " . json_encode($row) . "\n";
