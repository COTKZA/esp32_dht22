import 'package:flutter/material.dart';
import 'dart:async';
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
  Timer? _timer;
  bool autoRefresh = true;
  int refreshCount = 0;
  DateTime? lastUpdate;

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
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (autoRefresh && selectedDhtId != null && mounted) {
        _refreshLatestData();
      }
    });
  }

  void _stopAutoRefresh() {
    _timer?.cancel();
    _timer = null;
  }

  void _toggleAutoRefresh() {
    setState(() {
      autoRefresh = !autoRefresh;
    });
    if (autoRefresh) {
      _startAutoRefresh();
    } else {
      _stopAutoRefresh();
    }
  }

  Future<void> _refreshLatestData() async {
    if (selectedDhtId == null) return;

    try {
      final response = await _service.getLatestData(selectedDhtId!);
      setState(() {
        latest = response["latest"];
        refreshCount++;
        lastUpdate = DateTime.now();
        
        // เพิ่มข้อมูลใหม่เข้าไปในตารางถ้ามี
        if (response["newData"] != null && page == 1) {
          // ตรวจสอบว่าข้อมูลนี้ยังไม่มีใน list
          final newData = response["newData"];
          if (data.isEmpty || data[0]["id"] != newData["id"]) {
            data.insert(0, newData);
            // จำกัดจำนวนข้อมูลในตารางไม่ให้เกิน 10 รายการ
            if (data.length > 10) {
              data = data.sublist(0, 10);
            }
          }
        }
      });
    } catch (e) {
      debugPrint("Error refreshing latest data: $e");
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
        lastUpdate = DateTime.now();
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
      refreshCount = 0;
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
      refreshCount = 0;
    });
  }

  String _formatNumber(dynamic value) {
    if (value == null) return 'N/A';
    
    try {
      final numValue = value is String ? double.tryParse(value) : value;
      if (numValue == null) return 'N/A';
      return (numValue is num ? numValue : double.parse(numValue.toString()))
          .toStringAsFixed(1);
    } catch (e) {
      return value.toString();
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'N/A';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: selectedDhtName != null 
            ? Text(
                "📊 $selectedDhtName",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              )
            : const Text(
                "🌡️ ข้อมูล DHT Sensor",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 8,
        shadowColor: Colors.deepOrange.withOpacity(0.5),
        actions: [
          if (selectedDhtId != null) ...[
            // Auto Refresh Toggle Button
            IconButton(
              icon: Icon(
                autoRefresh ? Icons.pause : Icons.play_arrow,
                size: 24,
                color: autoRefresh ? Colors.greenAccent : Colors.white,
              ),
              onPressed: _toggleAutoRefresh,
              tooltip: autoRefresh ? "หยุดอัพเดทอัตโนมัติ" : "เริ่มอัพเดทอัตโนมัติ",
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 24),
              onPressed: fetchData,
              tooltip: "รีเฟรชข้อมูล",
            ),
            IconButton(
              icon: const Icon(Icons.sensors, size: 24),
              onPressed: _clearSelection,
              tooltip: "เปลี่ยน Sensor",
            ),
          ],
        ],
      ),
      body: loading
          ? _buildLoadingScreen()
          : selectedDhtId == null
              ? _buildSensorSelection()
              : _buildDataContent(),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepOrange.shade50,
            Colors.orange.shade50,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepOrange.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "กำลังโหลดข้อมูล...",
              style: TextStyle(
                fontSize: 16,
                color: Colors.deepOrange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorSelection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepOrange.shade50,
            Colors.orange.shade50,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepOrange.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.thermostat,
                      size: 32,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "เลือก DHT Sensor",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "กรุณาเลือก Sensor ที่ต้องการดูข้อมูลอุณหภูมิและความชื้น",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            if (sensors.isEmpty) ...[
              _buildNoSensorsCard(),
            ] else ...[
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.1,
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
      ),
    );
  }

  Widget _buildSensorCard(Map sensor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        shadowColor: Colors.deepOrange.withOpacity(0.3),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.orange.shade50,
              ],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _onSensorSelected(
                int.parse(sensor['id'].toString()), 
                sensor['name']?.toString() ?? 'Unnamed Sensor'
              ),
              splashColor: Colors.deepOrange.withOpacity(0.2),
              highlightColor: Colors.deepOrange.withOpacity(0.1),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon with background
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.device_thermostat,
                        size: 32,
                        color: Colors.deepOrange.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Sensor Name
                    Text(
                      sensor['name']?.toString() ?? 'Unnamed Sensor',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    
                    // Pin Info
                    Text(
                      "Pin: ${sensor['pin']?.toString() ?? 'N/A'}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Action Button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepOrange,
                            Colors.orange,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepOrange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "ดูข้อมูล",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoSensorsCard() {
    return Expanded(
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.deepOrange.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sensors_off,
                  size: 80,
                  color: Colors.deepOrange.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "ไม่พบ DHT Sensor",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "กรุณาเพิ่ม DHT Sensor ในหน้า Sensors ก่อน",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: fetchSensors,
                icon: const Icon(Icons.refresh),
                label: const Text("ลองใหม่"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepOrange.shade50,
            Colors.orange.shade50,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header with Sensor Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepOrange.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sensors,
                      size: 28,
                      color: autoRefresh ? Colors.green : Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedDhtName ?? 'Unknown Sensor',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange.shade800,
                          ),
                        ),
                        Text(
                          "ข้อมูลอุณหภูมิและความชื้น",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "ID: $selectedDhtId",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: autoRefresh ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          autoRefresh ? "🔄 อัตโนมัติ" : "⏸️ หยุด",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: autoRefresh ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Latest Data Cards
            if (latest != null) ...[
              Row(
                children: [
                  // Temperature Card
                  Expanded(
                    child: _buildValueCard(
                      title: "🌡️ อุณหภูมิ",
                      value: _formatNumber(latest!['temperature']),
                      unit: "°C",
                      color: Colors.red,
                      icon: Icons.thermostat,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Humidity Card
                  Expanded(
                    child: _buildValueCard(
                      title: "💧 ความชื้น",
                      value: _formatNumber(latest!['humidity']),
                      unit: "%",
                      color: Colors.blue,
                      icon: Icons.water_drop,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "อัพเดตล่าสุด: ${latest!['created_at'] ?? 'N/A'}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (lastUpdate != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              "อัพเดทข้อมูล: ${_formatTime(lastUpdate)} (อัพเดทแล้ว $refreshCount ครั้ง)",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Data Table Section
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrange.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.05),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.history,
                            color: autoRefresh ? Colors.green : Colors.deepOrange,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "ประวัติข้อมูล",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "ทั้งหมด ${data.length} รายการ",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Data Table
                    Expanded(
                      child: data.isEmpty
                          ? _buildNoDataCard()
                          : SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 24,
                                  dataRowMinHeight: 50,
                                  dataRowMaxHeight: 60,
                                  headingRowHeight: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(20),
                                      bottomRight: Radius.circular(20),
                                    ),
                                    color: Colors.white,
                                  ),
                                  columns: const [
                                    DataColumn(
                                      label: Text(
                                        "ID",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        "🌡️ อุณหภูมิ",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        "💧 ความชื้น",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        "📅 วันที่บันทึก",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows: data.map((row) => DataRow(
                                    cells: [
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.deepOrange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            row["id"]?.toString() ?? 'N/A',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.deepOrange,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              "${_formatNumber(row["temperature"])} °C",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              "${_formatNumber(row["humidity"])} %",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          row["created_at"]?.toString() ?? 'N/A',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )).toList(),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Pagination
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepOrange.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
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
                      backgroundColor: page > 1 ? Colors.deepOrange : Colors.grey.shade300,
                      foregroundColor: page > 1 ? Colors.white : Colors.grey.shade500,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios, size: 16),
                        SizedBox(width: 4),
                        Text("ย้อนกลับ"),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "หน้า $page / $totalPages",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: page < totalPages ? () {
                      setState(() => page++);
                      fetchData();
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: page < totalPages ? Colors.deepOrange : Colors.grey.shade300,
                      foregroundColor: page < totalPages ? Colors.white : Colors.grey.shade500,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("ถัดไป"),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueCard({
    required String title,
    required String value,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 16,
                  color: color.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.data_array,
              size: 60,
              color: Colors.deepOrange.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "ไม่พบข้อมูล",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "ยังไม่มีข้อมูลอุณหภูมิและความชื้นสำหรับ Sensor นี้",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}