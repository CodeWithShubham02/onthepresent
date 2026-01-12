import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateUserScreen extends StatefulWidget {
  final String cid;
  const CreateUserScreen({super.key, required this.cid});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {

  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  DateTime? doj;

  String gender = 'Male';
  String department = 'Executive';

  String? selectedBranchId;
  String? selectedBranchName;
  String? selectedLat;
  String? selectedLong;

  String? selectedShiftId;
  String? selectedShiftName;

  /// 📅 Date Picker
  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => doj = picked);
    }
  }
  Future<void> createUser() async {
    try {
      // 🔐 Firebase Auth
      UserCredential cred =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
      );

      String uid = cred.user!.uid;

      // 🔥 Firestore Save
      await FirebaseFirestore.instance
          .collection('subcompanies')
          .doc(widget.cid)
          .collection('employees')
          .doc(uid)
          .set({
        'uid': uid,
        'phone': phoneCtrl.text,
        'email': emailCtrl.text,
        'gender': gender,
        'department': department,
        'shiftId': selectedShiftId,
        'shiftName': selectedShiftName,
        'branchId': selectedBranchId,
        'branchName': selectedBranchName,
        'latitude': selectedLat,
        'longitude': selectedLong,
        'address': addressCtrl.text,
        'doj': doj,
        'android_id': '', // 🔥 EMPTY
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("User Created")));

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create User"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            _input(phoneCtrl, "Contact Number", TextInputType.phone),
            _input(emailCtrl, "Email", TextInputType.emailAddress),
            _input(passwordCtrl, "Password", TextInputType.text, true),

            ListTile(
              title: Text(doj == null
                  ? "Date of Joining"
                  : doj!.toString().split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: pickDate,
            ),

            _dropdownSimple(
              label: "Gender",
              value: gender,
              items: ['Male','Female','Other'],
              onChanged: (v)=> setState(()=> gender=v),
            ),

            _dropdownSimple(
              label: "Department",
              value: department,
              items: ['Team Leader','Executive'],
              onChanged: (v)=> setState(()=> department=v),
            ),
            const SizedBox(height: 5),
            /// 🔥 Branch Dropdown
            branchDropdown(),
            const SizedBox(height: 5),
            /// 🔥 Shift Dropdown
            shiftDropdown(),
            const SizedBox(height: 5),

            _input(addressCtrl, "Full Address"),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: createUser,
              child: const Text("Create Account"),
            )
          ],
        ),
      ),
    );
  }

  /// -------------------- WIDGETS --------------------

  Widget _input(TextEditingController c, String label,
      [TextInputType type = TextInputType.text, bool pass = false]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type,
        obscureText: pass,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _dropdownSimple({
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items
            .map((e)=>DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v)=> onChanged(v!),
      ),
    );
  }

  /// 🔥 Branch Dropdown Widget
  Widget branchDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('subcompanies')
          .doc(widget.cid)
          .collection('branches')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        return DropdownButtonFormField(
          hint: const Text("Select Branch"),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: snapshot.data!.docs.map((doc) {
            return DropdownMenuItem(
              value: doc.id,
              child: Text(doc['branchName']),
            );
          }).toList(),
          onChanged: (value) {
            final doc = snapshot.data!.docs
                .firstWhere((e) => e.id == value);

            setState(() {
              selectedBranchId = doc.id;
              selectedBranchName = doc['branchName'];
              selectedLat = doc['latitude'].toString();
              selectedLong = doc['longitude'].toString();
            });
          },
        );
      },
    );
  }

  /// 🔥 Shift Dropdown Widget
  Widget shiftDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('subcompanies')
          .doc(widget.cid)
          .collection('shifts')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        return DropdownButtonFormField(
          hint: const Text("Select Shift"),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: snapshot.data!.docs.map((doc) {
            return DropdownMenuItem(
              value: doc.id,
              child: Text(doc['shiftName']),
            );
          }).toList(),
          onChanged: (value) {
            final doc = snapshot.data!.docs
                .firstWhere((e) => e.id == value);

            setState(() {
              selectedShiftId = doc.id;
              selectedShiftName = doc['shiftName'];
            });
          },
        );
      },
    );
  }
}
