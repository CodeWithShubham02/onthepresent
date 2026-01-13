import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controller/shift_controller.dart';

class ShiftScreen extends StatefulWidget {
  final String cid;
  const ShiftScreen({super.key, required this.cid});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  final _shiftStartController = TextEditingController();
  final _shiftEndController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shift Screen"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openShiftDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ShiftController.getShifts(widget.cid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No shifts created"));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return Card(
                elevation:5,
                child: ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Column(
                    children: [
                      Text("Start - "+doc['shiftStart']),
                      Text("End - "+doc['shiftEnd']),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  /// 🔥 SHIFT CREATE DIALOG
  void _openShiftDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create Shift"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: widget.cid,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: "Company ID",
                ),
              ),

              const SizedBox(height: 10),



              const SizedBox(height: 10),

              TextField(
                controller: _shiftStartController,
                decoration: const InputDecoration(
                  labelText: "Shift Start Time",
                ),
              ),
              TextField(
                controller: _shiftEndController,
                decoration: const InputDecoration(
                  labelText: "Shift End Time",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: _createShift,
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  /// 🔥 CREATE SHIFT
  void _createShift() async {
    if (_shiftStartController.text.isEmpty || _shiftEndController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields required")),
      );
      return;
    }

    await ShiftController.createShift(
      cid: widget.cid,
      shiftStart: _shiftStartController.text.trim(),
      shiftEnd: _shiftEndController.text.trim(),
    );

    _shiftStartController.clear();
    _shiftEndController.clear();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Shift Created")),
    );
  }
}
