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

  // ดึงเฉพาะค่าล่าสุด (สำหรับ auto refresh)
  Future<Map<String, dynamic>> getLatestData(int dhtId) async {
    try {
      final res = await http.get(Uri.parse("$apiUrl?dht_id=$dhtId&page=1"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        
        if (data.containsKey('error')) {
          throw Exception(data['error']);
        }
        
        return {
          "latest": data["latest"],
          "newData": data["data"]?.isNotEmpty == true ? data["data"][0] : null
        };
      } else {
        throw Exception('Failed to load latest data: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}