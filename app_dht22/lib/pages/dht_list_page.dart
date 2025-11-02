import 'package:flutter/material.dart';
import '../services/dht_data_service.dart';
import 'dht_data_page.dart';

class DHTListPage extends StatefulWidget {
  const DHTListPage({super.key});

  @override
  State<DHTListPage> createState() => _DHTListPageState();
}

class _DHTListPageState extends State<DHTListPage> {
  final DHTDataService _service = DHTDataService();
  List sensors = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchSensors();
  }

  Future<void> fetchSensors() async {
    setState(() => loading = true);
    try {
      final sensorList = await _service.getDhtSensors();
      setState(() {
        sensors = sensorList;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      debugPrint("Error fetching sensors: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ไม่สามารถดึงข้อมูล Sensor ได้")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DHT Sensors"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : sensors.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sensors, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        "ไม่พบ DHT Sensor",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchSensors,
                        child: const Text("ลองใหม่"),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchSensors,
                  child: ListView.builder(
                    itemCount: sensors.length,
                    itemBuilder: (context, index) {
                      final sensor = sensors[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(Icons.thermostat,
                              color: Colors.blue),
                          title: Text(
                            sensor['name'] ?? 'Unnamed Sensor',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            "Pin: ${sensor['pin'] ?? 'N/A'}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DHTDataPage(
                                  dhtId: sensor['id'],
                                  dhtName: sensor['name'],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}