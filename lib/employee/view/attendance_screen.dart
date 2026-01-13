import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttendanceScreen extends StatefulWidget {
  final String cid;
  final String uid;

  const AttendanceScreen({super.key, required this.cid, required this.uid});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  Map<String, dynamic>? attendanceData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTodayAttendance();
  }

  String todayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}";
  }

  Future<void> fetchTodayAttendance() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('subcompanies')
          .doc(widget.cid)
          .collection('attendance')
          .doc(todayKey())
          .collection('records')
          .doc(widget.uid);

      final doc = await docRef.get();

      setState(() {
        attendanceData = doc.exists ? doc.data() : {};
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print(e.toString());
    }
  }

  String formatTime(Timestamp? ts) {
    if (ts == null) return "Not yet";
    final dt = ts.toDate();
    return "${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
  }

  String calculateWorkingHours(Timestamp? inTime, Timestamp? outTime) {
    if (inTime == null || outTime == null) return "-";
    final diff = outTime.toDate().difference(inTime.toDate());
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return "${hours}h ${minutes}m";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Attendance")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                )
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Attendance Details",
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Punch In
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Punch In:", style: TextStyle(fontSize: 16)),
                    Text(formatTime(attendanceData?['punchIn']?['time']),
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),

                // Punch Out
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Punch Out:", style: TextStyle(fontSize: 16)),
                    Text(formatTime(attendanceData?['punchOut']?['time']),
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),

                // Shift Start & End
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Shift Start:", style: TextStyle(fontSize: 16)),
                    Text(attendanceData?['shiftStart'] ?? '-',
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Shift End:", style: TextStyle(fontSize: 16)),
                    Text(attendanceData?['shiftEnd'] ?? '-',
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),

                // Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Status:", style: TextStyle(fontSize: 16)),
                    Text(attendanceData?['status'] ?? '-',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: attendanceData?['status'] == 'Present'
                                ? Colors.green
                                : Colors.red)),
                  ],
                ),
                const SizedBox(height: 8),

                // Working Duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Working Hours:", style: TextStyle(fontSize: 16)),
                    Text(
                      calculateWorkingHours(
                          attendanceData?['punchIn']?['time'],
                          attendanceData?['punchOut']?['time']),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
