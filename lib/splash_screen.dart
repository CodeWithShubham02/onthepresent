import 'dart:async';
import 'package:flutter/material.dart';
import 'package:onthepresent/login_screen.dart';
import 'package:onthepresent/subadmin/view/sub_home_screen.dart';
import 'package:onthepresent/employee/view/employee_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2)); // splash delay

    final prefs = await SharedPreferences.getInstance();
    final cid = prefs.getString('cid');
    final eid = prefs.getString('eid');

    if (cid != null && cid.isNotEmpty) {
      // 🔹 SubAdmin Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SubHomeScreen(cid: cid),
        ),
      );
    } else if (eid != null && eid.isNotEmpty) {
      // 🔹 Employee Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const EmployeeHomeScreen(),
        ),
      );
    } else {
      // 🔹 Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 70, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              "Onthepresent",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
