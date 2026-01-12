import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/company_model.dart';

class CompanyController {
  static Future<void> createCompany({
    required String email,
    required String password,
    required String companyName,
    required String address,
    required int numberOfEmployee,
  }) async {
    try {
      // 1️⃣ Create Auth User
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String cid = userCredential.user!.uid;

      // 2️⃣ Create Model
      CompanyModel company = CompanyModel(
        cid: cid,
        companyName: companyName,
        email: email,
        password: password,
        address: address,
        role: 'subAdmin',
        status: 'active',
        numberOfEmployee: numberOfEmployee,
      );

      // 3️⃣ Save to Firestore
      await FirebaseFirestore.instance
          .collection('subcompanies')
          .doc(cid)
          .set(company.toMap());
    } catch (e) {
      rethrow;
    }
  }
}
