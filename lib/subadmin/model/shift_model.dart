class ShiftModel {
  final String id;
  final String cid;
  final String shiftName;
  final DateTime createdAt;

  ShiftModel({
    required this.id,
    required this.cid,
    required this.shiftName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "cid": cid,
      "shiftName": shiftName,
      "createdAt": createdAt,
    };
  }
}
