class ShiftModel {
  final String id;
  final String cid;
  final String shiftStart;
  final String shiftEnd;
  final DateTime createdAt;

  ShiftModel({
    required this.id,
    required this.cid,
    required this.shiftStart,
    required this.shiftEnd,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "cid": cid,
      "shiftStart": shiftStart,
      "shiftEnd": shiftEnd,
      "createdAt": createdAt,
    };
  }
}
