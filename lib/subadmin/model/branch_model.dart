class BranchModel {
  final String id;
  final String cid;
  final String branchName;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  BranchModel({
    required this.id,
    required this.cid,
    required this.branchName,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "cid": cid,
      "branchName": branchName,
      "latitude": latitude,
      "longitude": longitude,
      "createdAt": createdAt,
    };
  }

  factory BranchModel.fromMap(String id, Map<String, dynamic> map) {
    return BranchModel(
      id: id,
      cid: map['cid'],
      branchName: map['branchName'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      createdAt: map['createdAt'].toDate(),
    );
  }
}
