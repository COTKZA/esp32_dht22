<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "esp32_dht22";

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) die(json_encode(["error" => $conn->connect_error]));

// ดึงรายการ DHT ตัวแรก (หรือเปลี่ยน query ตามต้องการ)
$result = $conn->query("SELECT id, pin FROM dht LIMIT 1");
if ($result->num_rows > 0) {
    $row = $result->fetch_assoc();
    // แปลง D2 → 2
    $pin_number = intval(substr($row['pin'],1));
    echo json_encode([
        "id" => intval($row['id']),
        "pin" => $pin_number
    ]);
} else {
    echo json_encode(["error" => "No DHT found"]);
}

$conn->close();
?>
