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
        title: const Text("All Branches",style: TextStyle(fontSize: 18),),
        centerTitle: true,
      ),
      body: StreamBuilder<List<BranchModel>>(
        stream: BranchController.getBranches(widget.cid),
        builder: (context, snapshot) {

          /// Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          /// Error
          if (snapshot.hasError) {
            return const Center(
              child: Text("Something went wrong"),
            );
          }

          /// Empty
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
                  leading: const Icon(
                    Icons.account_tree,
                    color: Colors.blue,
                    size: 30,
                  ),
                  title: Text(
                    branch.branchName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Latitude : ${branch.latitude}"),
                        Text("Longitude: ${branch.longitude}"),
                        Text("Range: ${branch.branchrange}"),
                      ],
                    ),
                  ),
                  trailing: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.red,size: 30,),
                        onPressed: () {
                          _showEditBranchDialog(branch);
                        },
                      ),

                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditBranchDialog(BranchModel branch) {
    final TextEditingController nameController =
    TextEditingController(text: branch.branchName);
    final TextEditingController rangeController =
    TextEditingController(text: branch.branchrange);
    final TextEditingController latController =
    TextEditingController(text: branch.latitude.toString());
    final TextEditingController lngController =
    TextEditingController(text: branch.longitude.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Branch"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Branch Name",
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: rangeController,
                  decoration: const InputDecoration(
                    labelText: "Range (meters)",
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: latController,
                  decoration: const InputDecoration(
                    labelText: "Latitude",
                  ),
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: lngController,
                  decoration: const InputDecoration(
                    labelText: "Longitude",
                  ),
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
                await BranchController.editBranch(
                  cid: widget.cid,
                  branchId: branch.id,
                  branchName: nameController.text.trim(),
                  branchrange: rangeController.text.trim(),
                  latitude: double.tryParse(latController.text),
                  longitude: double.tryParse(lngController.text),
                );

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Branch updated successfully")),
                );
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

}
