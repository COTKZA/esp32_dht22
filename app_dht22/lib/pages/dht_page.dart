import 'package:flutter/material.dart';
import '../services/dht_service.dart';

class DHTPage extends StatefulWidget {
  const DHTPage({super.key});

  @override
  State<DHTPage> createState() => _DHTPageState();
}

class _DHTPageState extends State<DHTPage> {
  final DHTService _service = DHTService();
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
      final data = await _service.getSensors();
      setState(() => sensors = data);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> showSensorDialog({Map? sensor}) async {
    final nameController = TextEditingController(text: sensor?['name'] ?? '');
    final pinController = TextEditingController(text: sensor?['pin'] ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.deepOrange.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              Icon(
                sensor == null ? Icons.add_circle : Icons.edit,
                color: Colors.deepOrange,
              ),
              const SizedBox(width: 12),
              Text(
                sensor == null ? 'เพิ่มเซนเซอร์' : 'แก้ไขเซนเซอร์',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
        ),
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อเซนเซอร์',
                    prefixIcon: Icon(Icons.thermostat, color: Colors.deepOrange),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: pinController,
                  decoration: const InputDecoration(
                    labelText: 'ขา (Pin)',
                    prefixIcon: Icon(Icons.memory, color: Colors.deepOrange),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || pinController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('กรุณากรอกข้อมูลให้ครบถ้วน'),
                    backgroundColor: Colors.deepOrange,
                  ),
                );
                return;
              }

              try {
                if (sensor == null) {
                  await _service.addSensor(nameController.text, pinController.text);
                } else {
                  await _service.updateSensor(int.parse(sensor['id']), nameController.text, pinController.text);
                }
                if (mounted) Navigator.pop(context);
                fetchSensors();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(sensor == null ? 'เพิ่มเซนเซอร์สำเร็จ' : 'แก้ไขเซนเซอร์สำเร็จ'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('เกิดข้อผิดพลาด'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteSensor(int id) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('ยืนยันการลบ'),
          ],
        ),
        content: const Text('คุณแน่ใจหรือไม่ที่จะลบเซนเซอร์นี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteSensor(id);
        fetchSensors();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ลบเซนเซอร์สำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาดในการลบ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: loading
          ? _buildLoadingScreen()
          : _buildSensorList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showSensorDialog(),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 8,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
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
            "กำลังโหลด Sensors...",
            style: TextStyle(
              fontSize: 16,
              color: Colors.deepOrange.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                    Icons.sensors,
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
                        "จัดการ DHT Sensors",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "จำนวน Sensors: ${sensors.length}",
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
          const SizedBox(height: 20),
          
          // Sensor List
          Expanded(
            child: sensors.isEmpty
                ? _buildNoSensorsCard()
                : ListView.builder(
                    itemCount: sensors.length,
                    itemBuilder: (context, index) {
                      final item = sensors[index];
                      return _buildSensorItem(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorItem(Map item) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white,
              Colors.orange.shade50,
            ],
          ),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.thermostat,
              color: Colors.deepOrange.shade700,
              size: 24,
            ),
          ),
          title: Text(
            item['name']?.toString() ?? 'ไม่ระบุชื่อ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            "ขา: ${item['pin']}",
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.deepOrange.shade700, size: 20),
                  onPressed: () => showSensorDialog(sensor: item),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.deepOrange.withOpacity(0.3),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red.shade600, size: 20),
                  onPressed: () => deleteSensor(int.parse(item['id'])),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoSensorsCard() {
    return Center(
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
                size: 60,
                color: Colors.deepOrange.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "ไม่พบ DHT Sensor",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "กดปุ่ม + เพื่อเพิ่ม Sensor ใหม่",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}