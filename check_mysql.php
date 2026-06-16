<?php
$conn = new mysqli("localhost", "root", "", "waqt_db");
$result = $conn->query("SELECT * FROM user_history WHERE date = '2026-06-17'");
if ($result->num_rows > 0) {
    echo "Found " . $result->num_rows . " rows.\n";
    while($row = $result->fetch_assoc()) {
        print_r($row);
    }
} else {
    echo "No rows found.\n";
}
$conn->query("DELETE FROM user_history");
echo "Deleted all user_history.\n";
