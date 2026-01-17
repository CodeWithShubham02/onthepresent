import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AllEmployeeList extends StatefulWidget {
  final String cid;
  const AllEmployeeList({super.key, required this.cid});

  @override
  State<AllEmployeeList> createState() => _AllEmployeeListState();
}

class _AllEmployeeListState extends State<AllEmployeeList> {
  String formatDateTime(Timestamp timestamp) {
    final DateTime dt = timestamp.toDate();
    return "${dt.day.toString().padLeft(2, '0')}-"
        "${dt.month.toString().padLeft(2, '0')}-"
        "${dt.year} "
        "${dt.hour.toString().padLeft(2, '0')}:"
        "${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Employee List",style: TextStyle(fontSize: 18),),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('subcompanies')
            .doc(widget.cid)
            .collection('employees')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final employees = snapshot.data!.docs;

          if (employees.isEmpty) {
            return const Center(child: Text("No employees found."));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: DataTable(
                headingRowColor: MaterialStateColor.resolveWith(
                        (states) => Colors.grey.shade200),
                border: TableBorder.all(
                    color: Colors.grey.shade400,
                    width: 1,
                    style: BorderStyle.solid),
                columnSpacing: 20,
                columns: const [

                  DataColumn(label: Text("Action")),
                  DataColumn(label: Text("Date")),
                  DataColumn(label: Text("User Name")),
                  DataColumn(label: Text("User Email")),
                  DataColumn(label: Text("User Phone")),
                  DataColumn(label: Text("IMEI No")),
                  DataColumn(label: Text("Gender")),
                  DataColumn(label: Text("Department")),
                  DataColumn(label: Text("Office Name")),
                  DataColumn(label: Text("Office Distance")),
                  DataColumn(label: Text("Office Lat")),
                  DataColumn(label: Text("Office Long")),
                  DataColumn(label: Text("Shift")),
                  DataColumn(label: Text("Status")),
                  DataColumn(label: Text("Date of Joing")),
                  DataColumn(label: Text("UID")),
                ],
                rows: employees.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  // Format date of joining
                  String doj = "-";
                  if (data['doj'] != null) {
                    final dt = (data['doj'] as Timestamp).toDate();
                    doj =
                    "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
                  }

                  return DataRow(cells: [
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          openEditEmployeeDialog(
                            context,
                            doc.id,   // 🔥 document id
                            data,     // 🔥 row data
                          );
                        },
                      ),
                    ),

                    DataCell(
                      Text(
                        formatDateTime(data['createdAt']),
                      ),
                    ),

                    DataCell(Text(data['name'] ?? '-')),
                    DataCell(Text(data['email'] ?? '-')),
                    DataCell(Text(data['phone'] ?? '-')),
                    DataCell(Text(data['android_id'] ?? '-')),
                    DataCell(Text(data['gender'] ?? '-')),
                    DataCell(Text(data['department'] ?? '-')),
                    DataCell(Text(data['branchName'] ?? '-')),
                    DataCell(Text(data['branchRange']?.toString() ?? '-')),
                    DataCell(Text(data['latitude']?.toString() ?? '-')),
                    DataCell(Text(data['longitude']?.toString() ?? '-')),
                    DataCell(Row(
                      children: [
                        Text(data['shiftStart'] ?? '-'),
                        Text(" - "),
                        Text(data['shiftEnd'] ?? '-'),
                      ],
                    )),
                    DataCell(Text(data['status'] ?? '-',
                        style: TextStyle(
                            color: data['status'] == 'active'
                                ? Colors.green
                                : Colors.red))),
                    DataCell(Text(doj)),
                    DataCell(Text(data['uid'] ?? '-')),
                  ]);
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
  void openEditEmployeeDialog(
      BuildContext context,
      String docId,
      Map<String, dynamic> data,
      ) {
    final nameCtrl = TextEditingController(text: data['name']);
    final emailCtrl = TextEditingController(text: data['email']);
    final phoneCtrl = TextEditingController(text: data['phone']);
    final genderCtrl = TextEditingController(text: data['gender']);
    final departmentCtrl = TextEditingController(text: data['department']);
    final branchNameCtrl = TextEditingController(text: data['branchName']);
    final branchRangeCtrl =
    TextEditingController(text: data['branchRange']?.toString());
    final latCtrl =
    TextEditingController(text: data['latitude']?.toString());
    final lngCtrl =
    TextEditingController(text: data['longitude']?.toString());
    final shiftStartCtrl = TextEditingController(text: data['shiftStart']);
    final shiftEndCtrl = TextEditingController(text: data['shiftEnd']);

    String status = data['status'] ?? 'active';

    DateTime? dojDate =
    data['doj'] != null ? (data['doj'] as Timestamp).toDate() : null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Employee"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _field(nameCtrl, "Name"),
              _field(emailCtrl, "Email"),
              _field(phoneCtrl, "Phone"),
              _field(genderCtrl, "Gender"),
              _field(departmentCtrl, "Department"),
              _field(branchNameCtrl, "Office Name"),
              _field(branchRangeCtrl, "Office Range (meters)",
                  keyboard: TextInputType.number),
              _field(latCtrl, "Office Latitude",
                  keyboard: TextInputType.number),
              _field(lngCtrl, "Office Longitude",
                  keyboard: TextInputType.number),
              _field(shiftStartCtrl, "Shift Start (HH:mm)"),
              _field(shiftEndCtrl, "Shift End (HH:mm)"),

              const SizedBox(height: 10),

              // STATUS
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(
                  labelText: "Status",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "active", child: Text("Active")),
                  DropdownMenuItem(value: "inactive", child: Text("Inactive")),
                ],
                onChanged: (v) => status = v!,
              ),

              const SizedBox(height: 10),

              // DOJ PICKER
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  dojDate == null
                      ? "Select Date of Joining"
                      : "DOJ: ${dojDate?.day}-${dojDate?.month}-${dojDate?.year}",
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dojDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    dojDate = picked;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('subcompanies')
                  .doc(widget.cid)
                  .collection('employees')
                  .doc(docId)
                  .update({
                'name': nameCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'gender': genderCtrl.text.trim(),
                'department': departmentCtrl.text.trim(),
                'branchName': branchNameCtrl.text.trim(),
                'branchRange': double.tryParse(branchRangeCtrl.text),
                'latitude': double.tryParse(latCtrl.text),
                'longitude': double.tryParse(lngCtrl.text),
                'shiftStart': shiftStartCtrl.text.trim(),
                'shiftEnd': shiftEndCtrl.text.trim(),
                'status': status,
                'doj': dojDate != null ? Timestamp.fromDate(dojDate!) : null,
                'updatedAt': FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Employee Updated Successfully")),
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
  Widget _field(
      TextEditingController controller,
      String label, {
        TextInputType keyboard = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }


}
