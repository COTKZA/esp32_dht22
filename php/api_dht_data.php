<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json; charset=UTF-8");

$conn = new mysqli("localhost", "root", "", "esp32_dht22");
if ($conn->connect_error) die(json_encode(["error" => $conn->connect_error]));

// ฟังก์ชันดึงข้อมูล DHT Sensor ทั้งหมด
function getDhtSensors($conn) {
    $result = $conn->query("SELECT * FROM dht ORDER BY id");
    $sensors = [];
    while($row = $result->fetch_assoc()) {
        $sensors[] = $row;
    }
    return $sensors;
}

// ฟังก์ชันดึงข้อมูล DHT Data
function getDhtData($conn, $dht_id, $page) {
    $limit = 10;
    $offset = ($page-1)*$limit;

    // ค่าล่าสุด
    $latestRes = $conn->query("
        SELECT dd.*, d.name as dht_name 
        FROM dht_data dd 
        LEFT JOIN dht d ON dd.dht_id = d.id 
        WHERE dd.dht_id=$dht_id 
        ORDER BY dd.id DESC LIMIT 1
    ");
    $latest = $latestRes->num_rows > 0 ? $latestRes->fetch_assoc() : null;

    // ข้อมูลแบ่งหน้า
    $result = $conn->query("
        SELECT * FROM dht_data 
        WHERE dht_id=$dht_id 
        ORDER BY id DESC 
        LIMIT $limit OFFSET $offset
    ");
    $data = [];
    while($row = $result->fetch_assoc()) {
        $data[] = $row;
    }

    // จำนวนทั้งหมด
    $totalRes = $conn->query("SELECT COUNT(*) AS total FROM dht_data WHERE dht_id=$dht_id");
    $total = $totalRes->fetch_assoc()['total'];
    $totalPages = ceil($total / $limit);

    return [
        "latest" => $latest,
        "data" => $data,
        "page" => $page,
        "totalPages" => $totalPages
    ];
}

// ตรวจสอบ action
$action = isset($_GET['action']) ? $_GET['action'] : '';

if ($action == 'get_sensors') {
    // ดึงรายการ DHT Sensor
    $sensors = getDhtSensors($conn);
    echo json_encode(["sensors" => $sensors]);
} else {
    // ดึงข้อมูล DHT Data
    $dht_id = isset($_GET['dht_id']) ? intval($_GET['dht_id']) : 0;
    $page = isset($_GET['page']) ? intval($_GET['page']) : 1;
    
    if ($dht_id == 0) {
        // แทนที่จะส่ง error, ส่งรายการ sensors กลับไป
        $sensors = getDhtSensors($conn);
        echo json_encode([
            "sensors" => $sensors,
            "message" => "กรุณาเลือก DHT Sensor"
        ]);
    } else {
        $result = getDhtData($conn, $dht_id, $page);
        echo json_encode($result);
    }
}

$conn->close();
?>