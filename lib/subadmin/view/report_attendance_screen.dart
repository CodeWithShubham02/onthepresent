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

class ReportAttendanceScreen extends StatefulWidget {
  final String cid;
  const ReportAttendanceScreen({super.key, required this.cid});

  @override
  State<ReportAttendanceScreen> createState() =>
      _ReportAttendanceScreenState();
}

class _ReportAttendanceScreenState extends State<ReportAttendanceScreen> {
  DateTimeRange? selectedDateRange;
  bool isLoading = false;
  String searchText = "";

  List<Map<String, dynamic>> attendanceRecords = [];
  List<Map<String, dynamic>> filteredRecords = [];

  // ---------------- DATE KEY ----------------
  String dateKey(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  // ---------------- PICK RANGE ----------------
  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      selectedDateRange = picked;
      await fetchAttendanceRange();
    }
  }

  // ---------------- FETCH DATA ----------------
  Future<void> fetchAttendanceRange() async {
    if (selectedDateRange == null) return;

    setState(() {
      isLoading = true;
      attendanceRecords.clear();
      filteredRecords.clear();
    });

    DateTime current = selectedDateRange!.start;

    while (!current.isAfter(selectedDateRange!.end)) {
      final snap = await FirebaseFirestore.instance
          .collection('subcompanies')
          .doc(widget.cid)
          .collection('attendance')
          .doc(dateKey(current))
          .collection('records')
          .get();

      for (var doc in snap.docs) {
        final data = doc.data();
        data['attendanceDate'] = dateKey(current);
        attendanceRecords.add(data);
      }
      current = current.add(const Duration(days: 1));
    }

    applyFilter();
    setState(() => isLoading = false);
  }

  // ---------------- FILTER ----------------
  void applyFilter() {
    filteredRecords = attendanceRecords.where((e) {
      final name = e['name']?.toString().toLowerCase() ?? '';
      final uid = e['uid']?.toString().toLowerCase() ?? '';
      return name.contains(searchText) || uid.contains(searchText);
    }).toList();
  }

  // ---------------- FORMAT ----------------
  String formatTime(Timestamp? ts) =>
      ts == null ? "-" : DateFormat('HH:mm').format(ts.toDate());

  String formatDate(String d) =>
      DateFormat('dd-MM-yyyy').format(DateTime.parse(d));

  // ---------------- PDF EXPORT ----------------
  Future<void> exportAttendancePdf() async {
    if (filteredRecords.isEmpty) {
      Get.snackbar("Error", "No data to export");
      return;
    }

    await Permission.storage.request();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Text(
            "Employee Attendance Report",
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),

          pw.Table.fromTextArray(
            border: pw.TableBorder.all(width: 0.5),
            cellAlignment: pw.Alignment.centerLeft,
            headers: const [
              "Location",
              "Date",
              "Employee ID",
              "Name",
              "Department",
              "Punch In",
              "Punch Out",
              "Punch In Remark",
              "Punch Out Remark",
              "Punch In Image",
              "Punch Out Image",
              "Shift Start",
              "Shift End",
              "Status",
              "Working Hours",
              "Total Break Minutes",
            ],
            data: filteredRecords.map((e) {
              final punchIn = e['punchIn']?['time'] as Timestamp?;
              final punchOut = e['punchOut']?['time'] as Timestamp?;

              String workingHours = "-";
              if (punchIn != null && punchOut != null) {
                final diff =
                punchOut.toDate().difference(punchIn.toDate());
                workingHours =
                "${diff.inHours}h ${diff.inMinutes % 60}m";
              }

              return [
                "${e['currentLat'] ?? '-'}, ${e['currentLng'] ?? '-'}",
                formatDate(e['attendanceDate']),
                e['uid'] ?? "-",
                e['name'] ?? "-",
                e['department'] ?? "-",
                formatTime(punchIn),
                formatTime(punchOut),
                e['punchIn']?['remark'] ?? "-",
                e['punchOut']?['remark'] ?? "-",
                e['punchIn']?['image'] ?? "-",
                e['punchOut']?['image'] ?? "-",
                e['shiftStart'] ?? "-",
                e['shiftEnd'] ?? "-",
                e['status'] ?? "-",
                workingHours,
                e['totalBreakMinutes']?.toString() ?? "-",
              ];
            }).toList(),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final path =
        "${dir.path}/Attendance_${Random().nextInt(1000)}.pdf";

    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(path)],
        text: "Attendance Report");
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Report",style: TextStyle(fontSize: 18),),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: pickDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: exportAttendancePdf,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search by name or ID",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                searchText = v.toLowerCase();
                setState(applyFilter);
              },
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Location")),
                  DataColumn(label: Text("Date")),
                  DataColumn(label: Text("ID")),
                  DataColumn(label: Text("Name")),
                  DataColumn(label: Text("Dept")),
                  DataColumn(label: Text("In")),
                  DataColumn(label: Text("Out")),
                  DataColumn(label: Text("In Remark")),
                  DataColumn(label: Text("Out Remark")),
                  DataColumn(label: Text("Shift Start")),
                  DataColumn(label: Text("Shift End")),
                  DataColumn(label: Text("Status")),
                  DataColumn(label: Text("Hours")),
                  DataColumn(label: Text("Break Min")),
                ],
                rows: filteredRecords.map((e) {
                  final punchIn =
                  e['punchIn']?['time'] as Timestamp?;
                  final punchOut =
                  e['punchOut']?['time'] as Timestamp?;

                  String hours = "-";
                  if (punchIn != null && punchOut != null) {
                    final diff = punchOut
                        .toDate()
                        .difference(punchIn.toDate());
                    hours =
                    "${diff.inHours}h ${diff.inMinutes % 60}m";
                  }

                  return DataRow(cells: [
                    DataCell(Text(
                        "${e['currentLat'] ?? '-'}, ${e['currentLng'] ?? '-'}")),
                    DataCell(Text(formatDate(e['attendanceDate']))),
                    DataCell(Text(e['uid'] ?? "-")),
                    DataCell(Text(e['name'] ?? "-")),
                    DataCell(Text(e['department'] ?? "-")),
                    DataCell(Text(formatTime(punchIn))),
                    DataCell(Text(formatTime(punchOut))),
                    DataCell(Text(e['punchIn']?['remark'] ?? "-")),
                    DataCell(Text(e['punchOut']?['remark'] ?? "-")),
                    DataCell(Text(e['shiftStart'] ?? "-")),
                    DataCell(Text(e['shiftEnd'] ?? "-")),
                    DataCell(Text(e['status'] ?? "-")),
                    DataCell(Text(hours)),
                    DataCell(Text(
                        e['totalBreakMinutes']?.toString() ?? "-")),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
