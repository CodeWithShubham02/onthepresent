import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/branch_model.dart';

class BranchController {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  /// CREATE BRANCH
  static Future<void> createBranch({
    required String cid,
    required String branchName,
    required String branchrange,
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
      branchrange: branchrange,
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
  /// UPDATE / EDIT BRANCH
  static Future<void> editBranch({
    required String cid,
    required String branchId,
    String? branchName,
    String? branchrange,
    double? latitude,
    double? longitude,
  }) async {
    final branchRef = _firestore
        .collection('subcompanies')
        .doc(cid)
        .collection('branches')
        .doc(branchId);

    Map<String, dynamic> updateData = {};

    if (branchName != null) {
      updateData['branchName'] = branchName;
    }
    if (branchrange != null) {
      updateData['branchrange'] = branchrange;
    }
    if (latitude != null) {
      updateData['latitude'] = latitude;
    }
    if (longitude != null) {
      updateData['longitude'] = longitude;
    }

    if (updateData.isNotEmpty) {
      updateData['updatedAt'] = DateTime.now();
      await branchRef.update(updateData);
    }
  }

}
