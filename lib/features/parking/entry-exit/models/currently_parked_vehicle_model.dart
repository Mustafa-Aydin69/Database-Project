class CurrentlyParkedVehicleModel {
  final String plateNumber;
  final String vehicleType;
  final String ownerName;
  final DateTime checkInTime;
  final String parkingLot;
  final String spotCode;
  CurrentlyParkedVehicleModel({
    required this.plateNumber,
    required this.vehicleType,
    required this.ownerName,
    required this.checkInTime,
    required this.parkingLot,
    required this.spotCode,
  });
  factory CurrentlyParkedVehicleModel.fromJson(Map<String, dynamic> json) {
    DateTime parseCheckIn(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is String) {
        final parsed = DateTime.tryParse(v);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }
    return CurrentlyParkedVehicleModel(
      plateNumber: (json['plateNumber'] as String?) ?? '',
      vehicleType: (json['vehicleType'] as String?) ?? '',
      ownerName: (json['ownerName'] as String?) ?? '',
      checkInTime: parseCheckIn(json['checkInTime']),
      parkingLot: (json['parkingLot'] as String?) ?? '',
      spotCode: (json['spotCode'] as String?) ?? '',
    );
  }
}
