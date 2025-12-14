class RecentCheckInModel {
  final String plateNumber;
  final String vehicleType;
  final DateTime checkInTime;
  final String spot;

  RecentCheckInModel({
    required this.plateNumber,
    required this.vehicleType,
    required this.checkInTime,
    required this.spot,
  });

  factory RecentCheckInModel.fromJson(Map<String, dynamic> json) {
    return RecentCheckInModel(
      plateNumber: (json['plateNumber'] as String?) ?? '',
      vehicleType: (json['vehicleType'] as String?) ?? '',
      checkInTime: DateTime.parse(json['checkInTime'] as String),
      spot: (json['spot'] as String?) ?? '',
    );
  }
}

