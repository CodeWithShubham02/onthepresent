import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AllEmployeeList extends StatefulWidget {
  final String cid;
  const AllEmployeeList({super.key, required this.cid});

  @override
  State<AllEmployeeList> createState() => _AllEmployeeListState();
}

class _AllEmployeeListState extends State<AllEmployeeList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Employee List"),
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
                  DataColumn(label: Text("UID")),
                  DataColumn(label: Text("Name")),
                  DataColumn(label: Text("Email")),
                  DataColumn(label: Text("Phone")),
                  DataColumn(label: Text("Department")),
                  DataColumn(label: Text("Branch")),
                  DataColumn(label: Text("Shift")),
                  DataColumn(label: Text("Status")),
                  DataColumn(label: Text("DOJ")),
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
                    DataCell(Text(data['uid'] ?? '-')),
                    DataCell(Text(data['name'] ?? '-')),
                    DataCell(Text(data['email'] ?? '-')),
                    DataCell(Text(data['phone'] ?? '-')),
                    DataCell(Text(data['department'] ?? '-')),
                    DataCell(Text(data['branchName'] ?? '-')),
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
                  ]);
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
