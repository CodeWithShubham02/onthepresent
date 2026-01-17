import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreateDepartmentScreen extends StatefulWidget {
  final String cid;
  const CreateDepartmentScreen({super.key, required this.cid});

  @override
  State<CreateDepartmentScreen> createState() =>
      _CreateDepartmentScreenState();
}

class _CreateDepartmentScreenState extends State<CreateDepartmentScreen> {
  final TextEditingController deptCtrl = TextEditingController();

  // 🔹 Add Department
  Future<void> addDepartment() async {
    if (deptCtrl.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('subcompanies')
        .doc(widget.cid)
        .collection('departments')
        .add({
      'name': deptCtrl.text.trim(),
      'cid': widget.cid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    deptCtrl.clear();
    Navigator.pop(context);
  }

  // 🔹 Open Dialog
  void openDepartmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Create Department"),
        content: TextField(
          controller: deptCtrl,
          decoration: const InputDecoration(
            labelText: "Department Name",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: addDepartment,
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Department",style: TextStyle(fontSize: 18),),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: openDepartmentDialog,
          ),
        ],
      ),

      // 🔥 Department List
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('subcompanies')
            .doc(widget.cid)
            .collection('departments')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No departments added"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: const Icon(Icons.apartment, color: Colors.blue),
                  title: Text(
                    doc['name'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text("CID: ${doc['cid']}"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
