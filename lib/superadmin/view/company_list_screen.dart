import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CompanyListScreen extends StatefulWidget {
  const CompanyListScreen({super.key});

  @override
  State<CompanyListScreen> createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends State<CompanyListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Company List")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('subcompanies').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No companies found"));
          }

          final companies = snapshot.data!.docs;

          return ListView.builder(
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final company = companies[index];
              final name = company['companyName'] ?? "No Name";
              final email = company['email'] ?? "No Email";
              final address = company['address'] ?? "No Address";
              final status = company['status'] ?? "No Address";
              final employees = company['numberOfEmployee']?.toString() ?? "0";

              return Card(
                margin:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Email: $email"),
                      Text("Address: $address"),
                      Text("Employees: $employees"),
                      Text("status: $status"),
                    ],
                  ),
                  leading: IconButton(onPressed: (){}, icon: Icon(Icons.edit)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
