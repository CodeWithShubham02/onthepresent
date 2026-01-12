class CompanyModel {
  final String cid;
  final String companyName;
  final String email;
  final String password;
  final String address;
  final String role;
  final String status;
  final int numberOfEmployee;

  CompanyModel({
    required this.cid,
    required this.companyName,
    required this.email,
    required this.password,
    required this.address,
    required this.role,
    required this.status,
    required this.numberOfEmployee,
  });

  Map<String, dynamic> toMap() {
    return {
      'cid': cid,
      'companyName': companyName,
      'email': email,
      'password':password,
      'address': address,
      'role': role,
      'status': status,
      'numberOfEmployee': numberOfEmployee,
      'createdAt': DateTime.now(),
    };
  }
}
