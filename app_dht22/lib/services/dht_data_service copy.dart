import 'dart:convert';
import 'package:http/http.dart' as http;

class DHTDataService {
  final String apiUrl = "http://localhost:8000/api_dht_data.php";

  // ดึงรายการ DHT Sensor
  Future<List<dynamic>> getDhtSensors() async {
    try {
      final res = await http.get(Uri.parse("$apiUrl?action=get_sensors"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data["sensors"] ?? [];
      } else {
        throw Exception('Failed to load sensors: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ดึงข้อมูล DHT Data
  Future<Map<String, dynamic>> getDHTData(int dhtId, int page) async {
    try {
      final res = await http.get(Uri.parse("$apiUrl?dht_id=$dhtId&page=$page"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        
        // ตรวจสอบว่ามี error หรือไม่
        if (data.containsKey('error')) {
          throw Exception(data['error']);
        }
        
        return data;
      } else {
        throw Exception('Failed to load data: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ดึงข้อมูลเริ่มต้น (sensors เท่านั้น)
  Future<Map<String, dynamic>> getInitialData() async {
    try {
      final res = await http.get(Uri.parse("$apiUrl"));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception('Failed to load initial data: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}