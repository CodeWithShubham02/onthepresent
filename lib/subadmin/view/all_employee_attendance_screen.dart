import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AllEmployeeAttendanceScreen extends StatefulWidget {
  final String cid;

  const AllEmployeeAttendanceScreen({super.key, required this.cid});

  @override
  State<AllEmployeeAttendanceScreen> createState() =>
      _AllEmployeeAttendanceScreenState();
}

class _AllEmployeeAttendanceScreenState
    extends State<AllEmployeeAttendanceScreen> {

  DateTime selectedDate = DateTime.now();
  String? selectedDepartment;

  // ---------------- DATE KEY ----------------
  String dateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // ---------------- PICK DATE ----------------
  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // ---------------- FILTER DIALOG ----------------
  void showFilterDialog() {
    final TextEditingController deptCtrl =
    TextEditingController(text: selectedDepartment);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Filter Attendance"),
        content: TextField(
          controller: deptCtrl,
          decoration: const InputDecoration(
            labelText: "Department",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                selectedDepartment =
                deptCtrl.text.trim().isEmpty ? null : deptCtrl.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text("Apply"),
          ),
        ],
      ),
    );
  }

  // ---------------- MAP ----------------
  Future<void> openGoogleMap(double lat, double lng) async {
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ---------------- FORMATTERS ----------------
  String formatTime(Timestamp? ts) {
    if (ts == null) return "-";
    final dt = ts.toDate();
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  String formatDate(Timestamp? ts) {
    if (ts == null) return "-";
    final dt = ts.toDate();
    return "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Attendance"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: pickDate,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: showFilterDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('subcompanies')
            .doc(widget.cid)
            .collection('attendance')
            .doc(dateKey(selectedDate))
            .collection('records')
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No attendance records found"),
            );
          }

          /// FILTER DATA
          final records = snapshot.data!.docs.where((doc) {
            if (selectedDepartment == null) return true;
            final data = doc.data() as Map<String, dynamic>;
            return (data['department'] ?? '')
                .toString()
                .toLowerCase()
                .contains(selectedDepartment!.toLowerCase());
          }).toList();

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DataTable(
                headingRowColor: MaterialStateColor.resolveWith(
                        (states) => Colors.grey.shade200),
                border: TableBorder.all(
                    color: Colors.grey.shade400, width: 1),
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text("Location")),
                  DataColumn(label: Text("Date")),
                  DataColumn(label: Text("Employee ID")),
                  DataColumn(label: Text("Name")),
                  DataColumn(label: Text("Department")),
                  DataColumn(label: Text("Punch In")),
                  DataColumn(label: Text("Punch Out")),
                  DataColumn(label: Text("Status")),
                  DataColumn(label: Text("Working Hours")),
                ],
                rows: records.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final punchIn = data['punchIn']?['time'] as Timestamp?;
                  final punchOut = data['punchOut']?['time'] as Timestamp?;

                  String workingHours = "-";
                  if (punchIn != null && punchOut != null) {
                    final diff =
                    punchOut.toDate().difference(punchIn.toDate());
                    workingHours =
                    "${diff.inHours}h ${diff.inMinutes % 60}m";
                  }

                  return DataRow(cells: [
                    DataCell(
                      InkWell(
                        onTap: () {
                          final lat = data['currentLat'];
                          final lng = data['currentLng'];
                          if (lat != null && lng != null) {
                            openGoogleMap(lat.toDouble(), lng.toDouble());
                          }
                        },
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    DataCell(Text(formatDate(punchIn))),
                    DataCell(Text(data['uid'] ?? '-')),
                    DataCell(Text(data['name'] ?? '-')),
                    DataCell(Text(data['department'] ?? '-')),
                    DataCell(Text(formatTime(punchIn))),
                    DataCell(Text(formatTime(punchOut))),
                    DataCell(
                      Text(
                        data['status'] ?? '-',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: data['status'] == 'Present'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                    DataCell(Text(workingHours)),
                  ]);
                }).toList(),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: (){},child: Icon(Icons.download),),
    );
  }
}
