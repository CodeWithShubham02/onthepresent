import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:onthepresent/employee/view/employee_home_screen.dart';
import 'package:onthepresent/subadmin/view/sub_home_screen.dart';

Future<void> loginUser(
    BuildContext context,
    String email,
    String password,
    String selectedRole,
    ) async {
  try {
    // 1️⃣ Firebase Auth Login
    UserCredential userCredential =
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    String uid = userCredential.user!.uid;

    // 2️⃣ Fetch user from Firestore
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('subcompanies')
        .doc(uid)
        .get();

    if (!doc.exists) {
      throw 'User record not found';
    }

    // 3️⃣ Role match
    if (doc['role'] != selectedRole) {
      throw 'Role mismatch';
    }

    // 4️⃣ Status check
    if (doc['status'] != 'active') {
      throw 'Account inactive';
    }

    // 5️⃣ Navigation
    if (selectedRole == 'subAdmin') {
      print("companyid ----------------");
      print(uid);
      print("companyid ----------------");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) =>  SubHomeScreen(cid:uid)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EmployeeHomeScreen()),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}
