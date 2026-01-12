import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:onthepresent/superadmin/controller/company_controller.dart';
import 'package:onthepresent/superadmin/view/super_home_screen.dart';

class CreateCompany extends StatefulWidget {
  const CreateCompany({super.key});

  @override
  State<CreateCompany> createState() => _CreateCompanyState();
}

class _CreateCompanyState extends State<CreateCompany> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController empController = TextEditingController();

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Company")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey, // Form key for validation
          child: Column(
            children: [
              _input(nameController, "Company Name", validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter company name";
                }
                return null;
              }),
              _input(emailController, "Company Email", validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter email";
                }
                if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$")
                    .hasMatch(value.trim())) {
                  return "Please enter a valid email";
                }
                return null;
              }),
              _input(passwordController, "Password",
                  isPassword: true, validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter password";
                    }
                    if (value.trim().length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  }),
              _input(addressController, "Company Address", validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter company address";
                }
                return null;
              }),
              _input(empController, "Number of Employees",
                  keyboard: TextInputType.number, validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter number of employees";
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return "Please enter a valid number";
                    }
                    return null;
                  }),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: isLoading ? null : _createCompany,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create Account"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController controller, String label,
      {bool isPassword = false,
        TextInputType keyboard = TextInputType.text,
        String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboard,
        validator: validator, // Add validator here
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _createCompany() async {
    if (!_formKey.currentState!.validate()) {
      // Form validation failed
      return;
    }

    setState(() => isLoading = true);

    try {
      await CompanyController.createCompany(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        companyName: nameController.text.trim(),
        address: addressController.text.trim(),
        numberOfEmployee: int.parse(empController.text.trim()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Company Created Successfully",
            style: TextStyle(color: Colors.black),
          ),
        ),
      );

      Get.offAll(() => SuperHomeScreen());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => isLoading = false);
  }
}
