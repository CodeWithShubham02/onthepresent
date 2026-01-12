import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:onthepresent/superadmin/view/company_list_screen.dart';
import 'package:onthepresent/superadmin/view/create_company.dart';

class SuperHomeScreen extends StatefulWidget {
  const SuperHomeScreen({super.key});

  @override
  State<SuperHomeScreen> createState() => _SuperHomeScreenState();
}

class _SuperHomeScreenState extends State<SuperHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Super Admin"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [

            _buildGridItem(
              icon: Icons.person_add,
              title: 'Create company',
              onTap: () {
               Get.to(()=>CreateCompany());
              },
            ),

            _buildGridItem(
              icon: Icons.people,
              title: 'Company List',
              onTap: () {
                Get.to(()=>CompanyListScreen());
              },
            ),

            _buildGridItem(
              icon: Icons.bar_chart,
              title: 'Reports',
              onTap: () {
                print('Reports Clicked');
              },
            ),

            _buildGridItem(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                print('Settings Clicked');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
