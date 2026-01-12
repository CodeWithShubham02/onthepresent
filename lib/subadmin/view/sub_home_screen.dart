import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:onthepresent/subadmin/view/branch_screen.dart';

class SubHomeScreen extends StatefulWidget {
  final String cid;
  const SubHomeScreen({super.key, required this.cid});

  @override
  State<SubHomeScreen> createState() => _SubHomeScreenState();
}

class _SubHomeScreenState extends State<SubHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sub Admin Dashboard"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Company ID: ${widget.cid}",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _dashboardBox(
                    title: "Create Branch",
                    icon: Icons.account_tree,
                    onTap: () {
                      Get.to(()=>BranchScreen(cid:"DZl9Y9MeqASWs3KP7aXwHSIM0OB2"));
                    },
                  ),
                  _dashboardBox(
                    title: "Create Shift",
                    icon: Icons.schedule,
                    onTap: () {
                      // Navigator.push(...)
                    },
                  ),
                  _dashboardBox(
                    title: "Create Employee",
                    icon: Icons.person_add,
                    onTap: () {
                      // Navigator.push(...)
                    },
                  ),
                  _dashboardBox(
                    title: "All Employees",
                    icon: Icons.people,
                    onTap: () {
                      // Navigator.push(...)
                    },
                  ),
                  _dashboardBox(
                    title: "Daily Attendance",
                    icon: Icons.fact_check,
                    onTap: () {
                      // Navigator.push(...)
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
