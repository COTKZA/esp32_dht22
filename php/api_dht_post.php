<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "esp32_dht22";

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) die(json_encode(["error" => $conn->connect_error]));

$data = json_decode(file_get_contents('php://input'), true);

if(isset($data['pin']) && isset($data['temperature']) && isset($data['humidity'])) {
    // หา dht_id จาก pin
    $pin = $conn->real_escape_string($data['pin']);
    $result = $conn->query("SELECT id FROM dht WHERE pin='$pin'");
    if($result->num_rows > 0){
        $row = $result->fetch_assoc();
        $dht_id = intval($row['id']);
        
        $temperature = floatval($data['temperature']);
        $humidity = floatval($data['humidity']);

        $conn->query("INSERT INTO dht_data (dht_id, temperature, humidity) VALUES ($dht_id, $temperature, $humidity)");
        echo json_encode(["success"=>true]);
    } else {
        echo json_encode(["error"=>"Pin not found"]);
    }
} else {
    echo json_encode(["error"=>"Invalid data"]);
}

$conn->close();
?>
