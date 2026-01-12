import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeModel {
  final String uid;
  final String phone;
  final String email;
  final String gender;
  final String department;
  final String shiftId;
  final String shiftName;
  final String branchId;
  final String branchName;
  final String latitude;
  final String longitude;
  final String address;
  final DateTime doj;
  final String androidId;
  final String status;
  final Timestamp createdAt;

  EmployeeModel({
    required this.uid,
    required this.phone,
    required this.email,
    required this.gender,
    required this.department,
    required this.shiftId,
    required this.shiftName,
    required this.branchId,
    required this.branchName,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.doj,
    required this.androidId,
    required this.status,
    required this.createdAt,
  });

  /// 🔥 Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phone': phone,
      'email': email,
      'gender': gender,
      'department': department,
      'shiftId': shiftId,
      'shiftName': shiftName,
      'branchId': branchId,
      'branchName': branchName,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'doj': Timestamp.fromDate(doj),
      'android_id': androidId,
      'status': status,
      'createdAt': createdAt,
    };
  }

  /// 🔁 From Firestore
  factory EmployeeModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return EmployeeModel(
      uid: d['uid'],
      phone: d['phone'],
      email: d['email'],
      gender: d['gender'],
      department: d['department'],
      shiftId: d['shiftId'],
      shiftName: d['shiftName'],
      branchId: d['branchId'],
      branchName: d['branchName'],
      latitude: d['latitude'],
      longitude: d['longitude'],
      address: d['address'],
      doj: (d['doj'] as Timestamp).toDate(),
      androidId: d['android_id'],
      status: d['status'],
      createdAt: d['createdAt'],
    );
  }
}
