import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/branch_model.dart';

class BranchController {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  /// CREATE BRANCH
  static Future<void> createBranch({
    required String cid,
    required String branchName,
    required double latitude,
    required double longitude,
  }) async {
    final branchRef = _firestore
        .collection('subcompanies')
        .doc(cid)
        .collection('branches')
        .doc(); // auto id

    final branch = BranchModel(
      id: branchRef.id,
      cid: cid,
      branchName: branchName,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
    );

    await branchRef.set(branch.toMap());
  }

  /// GET ALL BRANCHES
  static Stream<List<BranchModel>> getBranches(String cid) {
    return _firestore
        .collection('subcompanies')
        .doc(cid)
        .collection('branches')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BranchModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }
}
