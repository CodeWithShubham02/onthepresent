import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../employee/view/employee_home_screen.dart';
import '../../subadmin/view/sub_home_screen.dart';

Future<void> loginUser(
    BuildContext context,
    String email,
    String password, String selectedRole,
    ) async {
  try {
    // 1️⃣ Firebase Auth Login
    UserCredential userCredential =
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCredential.user!.uid;

    // 2️⃣ Check SubAdmin
    final subAdminDoc = await FirebaseFirestore.instance
        .collection('subcompanies')
        .doc(uid)
        .get();

    if (subAdminDoc.exists) {
      if (subAdminDoc['status'] != 'active') {
        throw 'Account inactive';
      }

      await saveSession(uid: uid, role: 'subAdmin', cid: uid);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SubHomeScreen(cid: uid),
        ),
      );
      return;
    }

    // 3️⃣ Check Employee (loop through subcompanies)
    final companies =
    await FirebaseFirestore.instance.collection('subcompanies').get();

    for (var company in companies.docs) {
      final empDoc = await FirebaseFirestore.instance
          .collection('subcompanies')
          .doc(company.id)
          .collection('employees')
          .doc(uid)
          .get();

      if (empDoc.exists) {
        if (empDoc['status'] != 'active') {
          throw 'Account inactive';
        }

        await saveSession(
          uid: uid,
          role: 'Employee',
          cid: company.id,
        );
        await handleAndroidIdLock(
          cid: company.id,
          eid: FirebaseAuth.instance.currentUser!.uid,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const EmployeeHomeScreen(),
          ),
        );
        return;
      }
    }

    throw 'User record not found';
  } catch (e) {
    print(e.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}
Future<String> getAndroidId() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  return androidInfo.id; // ANDROID_ID
}
Future<void> handleAndroidIdLock({
  required String cid,
  required String eid,
}) async {

  String androidId = await getAndroidId();

  final ref = FirebaseFirestore.instance
      .collection('subcompanies')
      .doc(cid)
      .collection('employees')
      .doc(eid);

  final doc = await ref.get();

  if (!doc.exists) throw 'User not found';

  String savedAndroidId = doc['android_id'] ?? '';

  // ✅ First Login
  if (savedAndroidId.isEmpty) {
    await ref.update({'android_id': androidId});
    return;
  }

  // ❌ Second Device
  if (savedAndroidId != androidId) {
    throw 'Account already logged in on another device';
  }
}

Future<void> saveSession({
  required String uid,
  required String role,
  required String cid,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('uid', uid);
  await prefs.setString('role', role);
  await prefs.setString('cid', cid);
}
