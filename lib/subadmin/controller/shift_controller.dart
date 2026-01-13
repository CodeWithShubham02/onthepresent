import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/shift_model.dart';

class ShiftController {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static Future<void> createShift({
    required String cid,
    required String shiftStart,
    required String shiftEnd,
  }) async {
    final ref = _firestore
        .collection('subcompanies')
        .doc(cid)
        .collection('shifts')
        .doc();

    final shift = ShiftModel(
      id: ref.id,
      cid: cid,
      shiftStart: shiftStart,
      shiftEnd: shiftEnd,
      createdAt: DateTime.now(),
    );

    await ref.set(shift.toMap());
  }

  static Stream<QuerySnapshot> getShifts(String cid) {
    return _firestore
        .collection('subcompanies')
        .doc(cid)
        .collection('shifts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
