import 'dart:convert';
import 'package:http/http.dart' as http;

class DHTService {
  final String apiUrl = "http://localhost:8000/api_dht.php";

  Future<List<dynamic>> getSensors() async {
    final res = await http.get(Uri.parse(apiUrl));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Failed to load sensors');
    }
  }

  Future<bool> addSensor(String name, String pin) async {
    final res = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'pin': pin}),
    );
    return res.statusCode == 200;
  }

  Future<bool> updateSensor(int id, String name, String pin) async {
    final res = await http.put(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': id, 'name': name, 'pin': pin}),
    );
    return res.statusCode == 200;
  }

  Future<bool> deleteSensor(int id) async {
    final res = await http.delete(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': id}),
    );
    return res.statusCode == 200;
  }
}
