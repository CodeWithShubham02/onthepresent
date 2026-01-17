import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
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
  List<Map<String, dynamic>> attendanceRecords = [];

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

  // ---------------- GOOGLE MAP ----------------
  Future<void> openGoogleMap(double lat, double lng) async {
    final Uri uri =
    Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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

  // ---------------- PDF EXPORT ----------------
  Future<void> exportAttendancePdf(
      BuildContext context, List<Map<String, dynamic>> records) async {
    var status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Storage Permission Denied")));
      return;
    }

    if (records.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("No attendance records to export")));
      return;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Attendance Report",
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.Table.fromTextArray(
                headers: [
                  "Location",
                  "Date",
                  "Employee ID",
                  "Name",
                  "Department",
                  "Punch In",
                  "Punch Out",
                  "Punch In Remark",
                  "Punch Out Remark",
                  "Shift Start",
                  "Shift End",
                  "Status",
                  "Working Hours",
                  "Total Break Minutes",
                ],
                data: records.map((record) {
                  final punchIn = record['punchIn']?['time'] as Timestamp?;
                  final punchOut = record['punchOut']?['time'] as Timestamp?;

                  String workingHours = "-";
                  if (punchIn != null && punchOut != null) {
                    final diff = punchOut.toDate().difference(punchIn.toDate());
                    workingHours = "${diff.inHours}h ${diff.inMinutes % 60}m";
                  }

                  return [
                    "${record['currentLat'] ?? '-'}, ${record['currentLng'] ?? '-'}",
                    formatDate(punchIn),
                    record['uid'] ?? "-",
                    record['name'] ?? "-",
                    record['department'] ?? "-",
                    formatTime(punchIn),
                    formatTime(punchOut),
                    record['punchIn']?['remark'] ?? "-",
                    record['punchOut']?['remark'] ?? "-",
                    record['shiftStart'] ?? "-",
                    record['shiftEnd'] ?? "-",
                    record['status'] ?? "-",
                    workingHours,
                    record['totalBreakMinutes']?.toString() ?? "-",
                  ];
                }).toList(),
                border: pw.TableBorder.all(width: 0.5),
                cellAlignment: pw.Alignment.centerLeft,
              )
            ],
          );
        },
      ),
    );

    Directory directory = Directory("/storage/emulated/0/Download");
    if (!directory.existsSync()) {
      directory = await getApplicationDocumentsDirectory();
    }

    final filePath =
        "${directory.path}/Attendance_${Random().nextInt(1000)}.pdf";
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("PDF saved at $filePath")));

    await Share.shareXFiles([XFile(filePath)], text: "Attendance Report");
  }

  // ---------------- BREAK DIALOG ----------------
  Future<void> showBreakDialog(String uid, String date) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('subcompanies')
          .doc(widget.cid)
          .collection('attendance')
          .doc(date)
          .collection('records')
          .doc(uid)
          .collection('breaks')
          .get();

      final breaks = snap.docs.map((doc) => doc.data()).toList();

      if (breaks.isEmpty) {
        Get.defaultDialog(
          title: "Breaks",
          content: const Text("No breaks found"),
          textConfirm: "OK",
          onConfirm: () => Get.back(),
        );
        return;
      }

      final breakWidgets = breaks.map((b) {
        final start = b['startTime'] is Timestamp
            ? (b['startTime'] as Timestamp).toDate()
            : DateTime.tryParse(b['startTime'] ?? '') ?? DateTime.now();
        final end = b['endTime'] is Timestamp
            ? (b['endTime'] as Timestamp).toDate()
            : DateTime.tryParse(b['endTime'] ?? '') ?? DateTime.now();
        final duration = end.difference(start);
        final formattedDuration =
            "${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}";

        return ListTile(
          leading: const Icon(Icons.timer),
          title: Text(
              "Start: ${DateFormat('hh:mm a').format(start)}  - End: ${DateFormat('hh:mm a').format(end)}"),
          subtitle: Text("Duration: $formattedDuration"),
        );
      }).toList();

      Get.defaultDialog(
        title: "Breaks",
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(shrinkWrap: true, children: breakWidgets),
        ),
        textConfirm: "Close",
        onConfirm: () => Get.back(),
      );
    } catch (e) {
      Get.snackbar("Error", "Failed to load breaks");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('subcompanies')
          .doc(widget.cid)
          .collection('attendance')
          .doc(dateKey(selectedDate))
          .collection('records')
          .snapshots(),
      builder: (context, snapshot) {
        attendanceRecords = snapshot.hasData
            ? snapshot.data!.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .where((data) {
          if (selectedDepartment == null) return true;
          return (data['department'] ?? '')
              .toString()
              .toLowerCase()
              .contains(selectedDepartment!.toLowerCase());
        }).toList()
            : [];

        return Scaffold(
          appBar: AppBar(
            title: const Text("Employee Attendance",style: TextStyle(fontSize: 18),),
            actions: [
              IconButton(icon: const Icon(Icons.calendar_month), onPressed: pickDate),
              IconButton(icon: const Icon(Icons.search), onPressed: showFilterDialog),
            ],
          ),
          body: snapshot.hasData && snapshot.data!.docs.isNotEmpty
              ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateColor.resolveWith(
                      (states) => Colors.grey.shade200),
              border: TableBorder.all(color: Colors.grey.shade400, width: 1),
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text("Location")),
                DataColumn(label: Text("Date")),
                DataColumn(label: Text("Employee ID")),
                DataColumn(label: Text("Name")),
                DataColumn(label: Text("Department")),
                DataColumn(label: Text("Punch In")),
                DataColumn(label: Text("Punch Out")),
                DataColumn(label: Text("Punch In Remark")),
                DataColumn(label: Text("Punch Out Remark")),
                DataColumn(label: Text("Punch In Image")),
                DataColumn(label: Text("Punch Out Image")),
                DataColumn(label: Text("Shift Start")),
                DataColumn(label: Text("Shift End")),
                DataColumn(label: Text("Status")),
                DataColumn(label: Text("Working Hours")),
                DataColumn(label: Text("Total Break Minutes")),
              ],
              rows: attendanceRecords.map((data) {
                final punchIn = data['punchIn']?['time'] as Timestamp?;
                final punchOut = data['punchOut']?['time'] as Timestamp?;

                String workingHours = "-";
                if (punchIn != null && punchOut != null) {
                  final diff = punchOut.toDate().difference(punchIn.toDate());
                  workingHours = "${diff.inHours}h ${diff.inMinutes % 60}m";
                }

                double parseDouble(dynamic value) {
                  if (value == null) return 0.0;
                  if (value is num) return value.toDouble();
                  return double.tryParse(value.toString()) ?? 0.0;
                }

                Widget linkText(String? url) {
                  if (url == null || url.isEmpty) return const Text("-");
                  return InkWell(
                    onTap: () async {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Icon(Icons.image, color: Colors.blue),
                  );
                }

                return DataRow(cells: [
                  DataCell(Row(
                    children: [
                      InkWell(
                        onTap: () {
                          final lat = parseDouble(data['currentLat']);
                          final lng = parseDouble(data['currentLng']);
                          if (lat != 0.0 && lng != 0.0) openGoogleMap(lat, lng);
                        },
                        child: const Icon(Icons.location_on, color: Colors.red),
                      ),
                      InkWell(
                        onTap: () {
                          final uid = data['uid'] ?? '-';
                          final date =
                          DateFormat('yyyy-MM-dd').format(selectedDate);
                          showBreakDialog(uid, date);
                        },
                        child: const Icon(Icons.watch_later, color: Colors.red),
                      ),
                    ],
                  )),
                  DataCell(Text(formatDate(punchIn))),
                  DataCell(Text(data['uid'] ?? '-')),
                  DataCell(Text(data['name'] ?? '-')),
                  DataCell(Text(data['department'] ?? '-')),
                  DataCell(Text(formatTime(punchIn))),
                  DataCell(Text(formatTime(punchOut))),
                  DataCell(Text(data['punchIn']?['remark']?.toString() ?? '-')),
                  DataCell(Text(data['punchOut']?['remark']?.toString() ?? '-')),
                  DataCell(linkText(data['punchIn']?['image']?.toString())),
                  DataCell(linkText(data['punchOut']?['image']?.toString())),
                  DataCell(Text(data['shiftStart']?.toString() ?? '-')),
                  DataCell(Text(data['shiftEnd']?.toString() ?? '-')),
                  DataCell(Text(data['status'] ?? '-')),
                  DataCell(Text(workingHours)),
                  DataCell(Text(data['totalBreakMinutes']?.toString() ?? '-')),
                ]);
              }).toList(),
            ),
          )
              : const Center(child: Text("No attendance records found")),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await exportAttendancePdf(context, attendanceRecords);
            },
            child: const Icon(Icons.download),
          ),
        );
      },
    );
  }
}
