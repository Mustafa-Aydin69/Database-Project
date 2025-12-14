class ExitVehicleModel {
  final String plateNumber;
  final String vehicleType;
  final String statusText;
  final String ownerName;
  final DateTime? checkInTime;
  final String parkingLot;
  final DateTime? checkOutTime;

  ExitVehicleModel({
    required this.plateNumber,
    required this.vehicleType,
    required this.statusText,
    required this.ownerName,
    required this.checkInTime,
    required this.parkingLot,
    required this.checkOutTime,
  });

  factory ExitVehicleModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? s) {
      if (s == null || s.isEmpty) return null;
      try {
        return DateTime.parse(s);
      } catch (_) {
        return null;
      }
    }

    return ExitVehicleModel(
      plateNumber: (json['PlateNumber'] ?? json['plateNumber'] ?? '') as String,
      vehicleType: (json['VehicleType'] ?? json['vehicleType'] ?? '') as String,
      statusText: (json['StatusText'] ?? json['statusText'] ?? 'Çıkış Yapıldı') as String,
      ownerName: (json['OwnerName'] ?? json['ownerName'] ?? '') as String,
      checkInTime: parseDate(json['CheckInTime'] ?? json['checkInTime'] as String?),
      parkingLot: (json['ParkingLot'] ?? json['parkingLot'] ?? '') as String,
      checkOutTime: parseDate(json['CheckOutTime'] ?? json['checkOutTime'] as String?),
    );
  }
}
