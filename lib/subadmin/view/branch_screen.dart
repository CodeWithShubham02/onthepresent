import 'package:flutter/material.dart';

import '../controller/branch_controller.dart';

class BranchScreen extends StatefulWidget {
  final String cid;
  const BranchScreen({super.key, required this.cid});

  @override
  State<BranchScreen> createState() => _BranchScreenState();
}

class _BranchScreenState extends State<BranchScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController cidController = TextEditingController();
  final TextEditingController branchController = TextEditingController();
  final TextEditingController latController = TextEditingController();
  final TextEditingController longController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    cidController.text = widget.cid; // auto insert CID
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Branch")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _input(cidController, "Company ID", enabled: false),

              _input(branchController, "Branch Name", validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Branch name is required";
                }
                return null;
              }),

              _input(latController, "Latitude",
                  keyboard: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Latitude is required";
                    }
                    if (double.tryParse(value) == null) {
                      return "Enter valid latitude";
                    }
                    return null;
                  }),

              _input(longController, "Longitude",
                  keyboard: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Longitude is required";
                    }
                    if (double.tryParse(value) == null) {
                      return "Enter valid longitude";
                    }
                    return null;
                  }),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: isLoading ? null : _createBranch,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create Branch"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(
      TextEditingController controller,
      String label, {
        bool enabled = true,
        TextInputType keyboard = TextInputType.text,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboard,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  void _createBranch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await BranchController.createBranch(
        cid: widget.cid,
        branchName: branchController.text.trim(),
        latitude: double.parse(latController.text.trim()),
        longitude: double.parse(longController.text.trim()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Branch Created Successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => isLoading = false);
  }
}
