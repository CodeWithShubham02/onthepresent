import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserAttendanceScreen extends StatefulWidget {
  final String cid;
  final String officeName;

  const UserAttendanceScreen({super.key, required this.cid, required this.officeName});

  @override
  State<UserAttendanceScreen> createState() => _UserAttendanceScreenState();
}

class _UserAttendanceScreenState extends State<UserAttendanceScreen> {
  bool isLoading = false;
  DateTime? selectedDate;
  List<Map<String, dynamic>> attendanceRecords = [];

  /// PICK DATE
  Future<void> pickDate() async {
    DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        isLoading = true;
        attendanceRecords = [];
      });
      await fetchAttendanceForDate(picked);
    }
  }

  /// FETCH ATTENDANCE RECORDS
  /// FETCH ATTENDANCE RECORDS WITH OFFICE FILTER
  Future<void> fetchAttendanceForDate(DateTime date) async {
    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final querySnapshot = await FirebaseFirestore.instance
          .collection('subcompanies')
          .doc(widget.cid)
          .collection('attendance')
          .doc(formattedDate)
          .collection('records')
          .get();

      // Filter records by officeName passed from previous screen
      final filteredRecords = querySnapshot.docs
          .map((doc) => doc.data())
          .where((record) =>
      record['officeName'] != null &&
          record['officeName'] == widget.officeName)
          .toList();

      setState(() {
        attendanceRecords = filteredRecords;
      });
    } catch (e) {
      print("Error fetching attendance: $e");
      setState(() {
        attendanceRecords = [];
      });
    } finally {
      setState(() => isLoading = false);
    }
  }


  /// FORMAT TIMESTAMP
  String formatTime(dynamic timestamp) {
    if (timestamp == null) return "-";
    if (timestamp is String) return timestamp;
    if (timestamp is Timestamp) {
      DateTime dt = timestamp.toDate();
      return DateFormat('yyyy-MM-dd hh:mm a').format(dt);
    }
    return "-";
  }

  /// SHOW IMAGE POPUP
  void showImagePopup(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(imageUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }

  /// BUILD TABLE FOR EACH RECORD
  Widget buildAttendanceTable(Map<String, dynamic> record) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: Colors.grey), // <-- border added
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FixedColumnWidth(100),
          1: FixedColumnWidth(80),
          2: FixedColumnWidth(80),
          3: FixedColumnWidth(80),
          4: FixedColumnWidth(80),
          5: FixedColumnWidth(80),
          6: FixedColumnWidth(80),
          7: FixedColumnWidth(80),
          8: FixedColumnWidth(120),
          9: FixedColumnWidth(120),
          10: FixedColumnWidth(120),
          11: FixedColumnWidth(120),
          12: FixedColumnWidth(80),
          13: FixedColumnWidth(80),
          14: FixedColumnWidth(80),
          15: FixedColumnWidth(80),
        },
        children: [
          // Header Row
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFFE0E0E0)),
            children: [
              Padding(padding: EdgeInsets.all(8), child: Text('Name')),
              Padding(padding: EdgeInsets.all(8), child: Text('Department')),
              Padding(padding: EdgeInsets.all(8), child: Text('Office')),
              Padding(padding: EdgeInsets.all(8), child: Text('Status')),
              Padding(padding: EdgeInsets.all(8), child: Text('Shift Start')),
              Padding(padding: EdgeInsets.all(8), child: Text('Shift End')),
              Padding(padding: EdgeInsets.all(8), child: Text('Working Min')),
              Padding(padding: EdgeInsets.all(8), child: Text('Break Min')),
              Padding(padding: EdgeInsets.all(8), child: Text('Punch In Time')),
              Padding(padding: EdgeInsets.all(8), child: Text('Punch Out Time')),
              Padding(padding: EdgeInsets.all(8), child: Text('Punch In Remark')),
              Padding(padding: EdgeInsets.all(8), child: Text('Punch Out Remark')),
              Padding(padding: EdgeInsets.all(8), child: Text('Punch In Img')),
              Padding(padding: EdgeInsets.all(8), child: Text('Punch Out Img')),
              Padding(padding: EdgeInsets.all(8), child: Text('currentLat')),
              Padding(padding: EdgeInsets.all(8), child: Text('currentLng')),
            ],
          ),
          // Data Row
          TableRow(
            children: [
              Padding(padding: const EdgeInsets.all(8), child: Text(record['name'] ?? "-")),
              Padding(padding: const EdgeInsets.all(8), child: Text(record['department'] ?? "-")),
              Padding(padding: const EdgeInsets.all(8), child: Text(record['officeName'] ?? "-")),
              Padding(padding: const EdgeInsets.all(8), child: Text(record['status'] ?? "-")),
              Padding(padding: const EdgeInsets.all(8), child: Text(record['shiftStart'] ?? "-")),
              Padding(padding: const EdgeInsets.all(8), child: Text(record['shiftEnd'] ?? "-")),
              Padding(padding: const EdgeInsets.all(8), child: Text(record['workingMinutes']?.toString() ?? "-")),
              Padding(padding: const EdgeInsets.all(8), child: Text(record['totalBreakMinutes']?.toString() ?? "-")),
              Padding(padding: const EdgeInsets.all(8), child: Text(formatTime(record['punchIn']?['time']))),
              Padding(padding: const EdgeInsets.all(8), child: Text(formatTime(record['punchOut']?['time']))),
              Padding(padding: const EdgeInsets.all(8), child: Text(record['punchIn']?['remark'] ?? "-")),
              Padding(padding: const EdgeInsets.all(8), child: Text(record['punchOut']?['remark'] ?? "-")),
              Padding(
                padding: const EdgeInsets.all(4),
                child: record['punchIn']?['image'] != null
                    ? InkWell(
                  onTap: () => showImagePopup(record['punchIn']['image']),
                  child: Image.network(record['punchIn']['image'], width: 50, height: 50),
                )
                    : const Text("-"),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: record['punchOut']?['image'] != null
                    ? InkWell(
                  onTap: () => showImagePopup(record['punchOut']['image']),
                  child: Image.network(record['punchOut']['image'], width: 50, height: 50),
                )
                    : const Text("-"),
              ),
              Padding(padding: const EdgeInsets.all(8), child: Text(record['currentLat']?.toString() ?? "-")),
              Padding(padding: const EdgeInsets.all(8), child: Text(record['currentLng']?.toString() ?? "-")),
            ],
          ),
        ],
      ),
    );
  }

  /// BUILD UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Attendance',style: TextStyle(fontSize: 18),)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              onPressed: pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(selectedDate == null
                  ? "Select Date"
                  : DateFormat('yyyy-MM-dd').format(selectedDate!)),
            ),
          ),
          const Divider(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : attendanceRecords.isEmpty
                ? const Center(child: Text("No attendance found"))
                : ListView.builder(
              itemCount: attendanceRecords.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child:
                  buildAttendanceTable(attendanceRecords[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
