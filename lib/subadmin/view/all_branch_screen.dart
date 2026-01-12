import 'package:flutter/material.dart';
import '../controller/branch_controller.dart';
import '../model/branch_model.dart';

class AllBranchScreen extends StatefulWidget {
  final String cid;
  const AllBranchScreen({super.key, required this.cid});

  @override
  State<AllBranchScreen> createState() => _AllBranchScreenState();
}

class _AllBranchScreenState extends State<AllBranchScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Branches"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<BranchModel>>(
        stream: BranchController.getBranches(widget.cid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No branches found"));
          }

          final branches = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: branches.length,
            itemBuilder: (context, index) {
              final branch = branches[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.account_tree, color: Colors.blue),
                  title: Text(
                    branch.branchName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Latitude: ${branch.latitude}"),
                      Text("Longitude: ${branch.longitude}"),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      //_deleteBranch(branch.id);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // void _deleteBranch(String branchId) async {
  //   await BranchController.deleteBranch(
  //     cid: widget.cid,
  //     branchId: branchId,
  //   );
  //
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text("Branch Deleted")),
  //   );
  // }
}
