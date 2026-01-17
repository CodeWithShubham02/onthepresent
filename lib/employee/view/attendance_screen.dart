import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AttendanceScreen extends StatefulWidget {
  final String cid;
  final String uid;


  const AttendanceScreen({
    super.key,
    required this.cid,
    required this.uid,

  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  Map<String, dynamic>? attendanceData;
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchAttendanceByDate(selectedDate);
  }

  // 🔹 Date Key (YYYY-MM-DD)
  String dateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // 🔹 Fetch Attendance
  Future<void> fetchAttendanceByDate(DateTime date) async {
    setState(() => isLoading = true);

    final doc = await FirebaseFirestore.instance
        .collection('subcompanies')
        .doc(widget.cid)
        .collection('attendance')
        .doc(dateKey(date))
        .collection('records')
        .doc(widget.uid)
        .get();

    setState(() {
      attendanceData = doc.exists ? doc.data() : {};
      isLoading = false;
    });
  }

  // 🔹 Time Formatter
  String formatTime(Timestamp? ts) {
    if (ts == null) return "-";
    final d = ts.toDate();
    return "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
  }

  // 🔹 Working Hours
  String workingHours() {
    if (attendanceData?['punchIn']?['time'] == null ||
        attendanceData?['punchOut']?['time'] == null) return "-";

    final inTime =
    (attendanceData!['punchIn']['time'] as Timestamp).toDate();
    final outTime =
    (attendanceData!['punchOut']['time'] as Timestamp).toDate();

    final diff = outTime.difference(inTime);
    return "${diff.inHours}h ${diff.inMinutes % 60}m";
  }

  // 🔹 URL Link
  Widget linkText(String? url) {
    if (url == null || url.isEmpty) return const Text("-");
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: const Text(
        "View",
        style: TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  // 🔹 Table Row
  DataRow row(String label, Widget value) {
    return DataRow(cells: [
      DataCell(Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600))),
      DataCell(value),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Attendance (${dateKey(selectedDate)})",
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
              );

              if (pickedDate != null) {
                selectedDate = pickedDate;
                fetchAttendanceByDate(pickedDate);
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : attendanceData == null || attendanceData!.isEmpty
          ? const Center(child: Text("No attendance found"))
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DataTableTheme(
              data: DataTableThemeData(
                headingRowColor: MaterialStateProperty.all(
                    Colors.grey.shade200),
                dividerThickness: 1,
              ),
              child: DataTable(
                columnSpacing: 50,
                columns: const [
                  DataColumn(label: Text("Field")),
                  DataColumn(label: Text("Value")),
                ],
                rows: [
                  row("Punch In",
                      Text(formatTime(attendanceData?['punchIn']?['time']))),

                  row("Punch Out",
                      Text(formatTime(attendanceData?['punchOut']?['time']))),

                  row("Punch In Remark",
                      Text(attendanceData?['punchIn']?['remark']?.toString() ?? "-")),

                  row("Punch Out Remark",
                      Text(attendanceData?['punchOut']?['remark']?.toString() ?? "-")),

                  row("Punch In Image",
                      linkText(attendanceData?['punchIn']?['image'])),

                  row("Punch Out Image",
                      linkText(attendanceData?['punchOut']?['image'])),

                  row("currentLat",
                      Text(attendanceData?['currentLat']?.toString() ?? "-")),

                  row("currentLng",
                      Text(attendanceData?['currentLng']?.toString() ?? "-")),

                  row("Shift Start",
                      Text(attendanceData?['shiftStart']?.toString() ?? "-")),

                  row("Shift End",
                      Text(attendanceData?['shiftEnd']?.toString() ?? "-")),

                  row(
                    "Status",
                    Text(
                      attendanceData?['status']?.toString() ?? "-",
                      style: TextStyle(
                        color: attendanceData?['status'] == 'Present'
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  row("Working Hours", Text(workingHours())),
                  row("Total break Time", Text(attendanceData?['totalBreakMinutes']?.toString() ?? "-")),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
