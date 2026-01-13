import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:onthepresent/employee/view/pouch_in_out_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../login_screen.dart';
import 'attendance_screen.dart';

class EmployeeHomeScreen extends StatefulWidget {
  final String uid;
  final String cid;

  const EmployeeHomeScreen({
    super.key,
    required this.uid,
    required this.cid,
  });

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  Map<String, dynamic>? employeeData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEmployeeData();
  }

  Future<void> fetchEmployeeData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('subcompanies')
          .doc(widget.cid)
          .collection('employees')
          .doc(widget.uid)
          .get();

      if (doc.exists) {
        employeeData = doc.data();
      }
    } catch (e) {
      debugPrint("Employee fetch error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> clearUid() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('uid');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Dashboard"),
        actions: [
          IconButton(
            onPressed: () async {
              await clearUid();
              Get.offAll(() => LoginScreen());
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 Employee Info Card
            employeeInfoCard(),

            const SizedBox(height: 20),

            // 📊 Dashboard
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _dashboardBox(
                    title: "Punch In / Punch Out",
                    icon: Icons.fingerprint,
                    onTap: () {
                      Get.to(() => PunchInOutScreen(
                        cid: widget.cid,
                        uid: widget.uid,
                          department:employeeData?['department'] ?? '-',
                          range:employeeData?['branchRange'] ?? '-',
                          name:employeeData?['name'] ?? '-',
                      ));
                    },
                  ),
                  _dashboardBox(
                    title: "My Attendance",
                    icon: Icons.event_available,
                    onTap: () {
                      Get.to(() => AttendanceScreen(
                        cid: widget.cid,
                        uid: widget.uid,
                      ));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🪪 Employee Info UI
  Widget employeeInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            infoRow("Employee ID", widget.uid),
            infoRow("Company ID", widget.cid),
            infoRow("Name", employeeData?['name'] ?? '-'),
            infoRow("Department", employeeData?['department'] ?? '-'),
            infoRow(
              "Shift",
              employeeData == null
                  ? "-"
                  : "${employeeData?['shiftStart'] ?? '-'} - ${employeeData?['shiftEnd'] ?? '-'}",
            ),
          ],
        ),
      ),
    );
  }

  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              "$title:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // 🧱 Dashboard Tile
  Widget _dashboardBox({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
