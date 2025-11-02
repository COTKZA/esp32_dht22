import 'package:flutter/material.dart';
import '../services/dht_data_service.dart';

class DHTDataPage extends StatefulWidget {
  final int? dhtId;
  final String? dhtName;

  const DHTDataPage({super.key, this.dhtId, this.dhtName});

  @override
  State<DHTDataPage> createState() => _DHTDataPageState();
}

class _DHTDataPageState extends State<DHTDataPage> {
  final DHTDataService _service = DHTDataService();
  Map<String, dynamic>? latest;
  List data = [];
  List sensors = [];
  int page = 1;
  int totalPages = 1;
  bool loading = true;
  int? selectedDhtId;
  String? selectedDhtName;

  @override
  void initState() {
    super.initState();
    if (widget.dhtId != null) {
      selectedDhtId = widget.dhtId;
      selectedDhtName = widget.dhtName;
      fetchData();
    } else {
      fetchSensors();
    }
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
        SnackBar(content: Text("ไม่สามารถดึงข้อมูล Sensor ได้: $e")),
      );
    }
  }

  Future<void> fetchData() async {
    if (selectedDhtId == null) return;

    setState(() => loading = true);
    try {
      final response = await _service.getDHTData(selectedDhtId!, page);
      setState(() {
        latest = response["latest"];
        data = response["data"] ?? [];
        totalPages = response["totalPages"] ?? 1;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      debugPrint("Error fetching DHT data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ไม่สามารถดึงข้อมูลได้: $e")),
      );
    }
  }

  void _onSensorSelected(int dhtId, String dhtName) {
    setState(() {
      selectedDhtId = dhtId;
      selectedDhtName = dhtName;
      page = 1;
      data = [];
      latest = null;
    });
    fetchData();
  }

  void _clearSelection() {
    setState(() {
      selectedDhtId = null;
      selectedDhtName = null;
      data = [];
      latest = null;
      page = 1;
    });
  }

  // ฟังก์ชันช่วยสำหรับแปลงค่าเป็นตัวเลขและจัดรูปแบบ
  String _formatNumber(dynamic value) {
    if (value == null) return 'N/A';
    
    try {
      // แปลงเป็นตัวเลขก่อน
      final numValue = value is String ? double.tryParse(value) : value;
      
      if (numValue == null) return 'N/A';
      
      // จัดรูปแบบเป็นทศนิยม 1 ตำแหน่ง
      return (numValue is num ? numValue : double.parse(numValue.toString()))
          .toStringAsFixed(1);
    } catch (e) {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: selectedDhtName != null 
            ? Text("ข้อมูล $selectedDhtName")
            : const Text("ข้อมูล DHT Sensor"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (selectedDhtId != null) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: fetchData,
              tooltip: "รีเฟรชข้อมูล",
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSelection,
              tooltip: "เปลี่ยน Sensor",
            ),
          ],
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : selectedDhtId == null
              ? _buildSensorSelection()
              : _buildDataContent(),
    );
  }

  Widget _buildSensorSelection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "เลือก DHT Sensor",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "กรุณาเลือก Sensor ที่ต้องการดูข้อมูลอุณหภูมิและความชื้น",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          
          if (sensors.isEmpty) ...[
            _buildNoSensorsCard(),
          ] else ...[
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: sensors.length,
                itemBuilder: (context, index) {
                  final sensor = sensors[index];
                  return _buildSensorCard(sensor);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSensorCard(Map sensor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onSensorSelected(
          int.parse(sensor['id'].toString()), 
          sensor['name']?.toString() ?? 'Unnamed Sensor'
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.thermostat,
                size: 40,
                color: Colors.green[700],
              ),
              const SizedBox(height: 8),
              Text(
                sensor['name']?.toString() ?? 'Unnamed Sensor',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                "Pin: ${sensor['pin']?.toString() ?? 'N/A'}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "ดูข้อมูล",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoSensorsCard() {
    return Expanded(
      child: Center(
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sensors_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  "ไม่พบ DHT Sensor",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "กรุณาเพิ่ม DHT Sensor ในหน้า Sensors ก่อน",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: fetchSensors,
                  icon: const Icon(Icons.refresh),
                  label: const Text("ลองใหม่"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataContent() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card แสดงค่าล่าสุด
          if (latest != null) ...[
            Card(
              color: Colors.lightBlue[50],
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          "ค่าล่าสุด - $selectedDhtName",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildInfoItem(
                          "🌡️ อุณหภูมิ",
                          "${_formatNumber(latest!['temperature'])} °C",
                          Colors.red,
                        ),
                        const SizedBox(width: 20),
                        _buildInfoItem(
                          "💧 ความชื้น",
                          "${_formatNumber(latest!['humidity'])} %",
                          Colors.blue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "🕒 วันที่: ${latest!['created_at'] ?? 'N/A'}",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Header ตารางข้อมูล
          Row(
            children: [
              const Text(
                "ประวัติข้อมูล",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                "Sensor: $selectedDhtName",
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // ตารางข้อมูล
          Expanded(
            child: data.isEmpty
                ? _buildNoDataCard()
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        dataRowMinHeight: 40,
                        dataRowMaxHeight: 60,
                        columns: const [
                          DataColumn(label: Text("ID", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("อุณหภูมิ (°C)", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("ความชื้น (%)", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("วันที่บันทึก", style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: data.map((row) => DataRow(
                          cells: [
                            DataCell(Text(row["id"]?.toString() ?? 'N/A')),
                            DataCell(Center(child: Text(
                              _formatNumber(row["temperature"]),
                              style: const TextStyle(color: Colors.red),
                            ))),
                            DataCell(Center(child: Text(
                              _formatNumber(row["humidity"]),
                              style: const TextStyle(color: Colors.blue),
                            ))),
                            DataCell(Text(row["created_at"]?.toString() ?? 'N/A')),
                          ],
                        )).toList(),
                      ),
                    ),
                  ),
          ),
          
          // Pagination
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: page > 1 ? () {
                    setState(() => page--);
                    fetchData();
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("ย้อนกลับ"),
                ),
                const SizedBox(width: 16),
                Text(
                  "หน้า $page / $totalPages",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: page < totalPages ? () {
                    setState(() => page++);
                    fetchData();
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("ถัดไป"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.data_array,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                "ไม่พบข้อมูล",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "ยังไม่มีข้อมูลอุณหภูมิและความชื้นสำหรับ Sensor นี้",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}