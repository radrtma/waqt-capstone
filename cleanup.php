<?php
$conn = new mysqli("localhost", "root", "", "waqt_db");
$conn->query("DELETE FROM user_history WHERE date = '2026-06-17'");
echo "Deleted " . $conn->affected_rows . " rows from user_history.";
