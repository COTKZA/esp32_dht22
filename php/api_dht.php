    <?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Content-Type: application/json; charset=UTF-8");

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "esp32_dht22";

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    die(json_encode(["error" => $conn->connect_error]));
}

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET': // อ่านข้อมูล
        $result = $conn->query("SELECT * FROM dht");
        $data = [];
        while ($row = $result->fetch_assoc()) {
            $data[] = $row;
        }
        echo json_encode($data);
        break;

    case 'POST': // เพิ่มข้อมูล
        $input = json_decode(file_get_contents('php://input'), true);
        $name = $conn->real_escape_string($input['name']);
        $pin = $conn->real_escape_string($input['pin']);
        $sql = "INSERT INTO dht (name, pin) VALUES ('$name', '$pin')";
        echo json_encode(["success" => $conn->query($sql)]);
        break;

    case 'PUT': // แก้ไขข้อมูล
        $input = json_decode(file_get_contents('php://input'), true);
        $id = intval($input['id']);
        $name = $conn->real_escape_string($input['name']);
        $pin = $conn->real_escape_string($input['pin']);
        $sql = "UPDATE dht SET name='$name', pin='$pin' WHERE id=$id";
        echo json_encode(["success" => $conn->query($sql)]);
        break;

    case 'DELETE': // ลบข้อมูล
        $input = json_decode(file_get_contents('php://input'), true);
        $id = intval($input['id']);
        $sql = "DELETE FROM dht WHERE id=$id";
        echo json_encode(["success" => $conn->query($sql)]);
        break;
}
$conn->close();
?>
