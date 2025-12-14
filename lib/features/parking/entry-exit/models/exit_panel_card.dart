class ExitPanelCard {
  final String plateNumber;
  final String vehicleType;
  final String status;
  final String owner;
  final DateTime? entryTime;
  final String location;
  final DateTime? exitTime;

  ExitPanelCard({
    required this.plateNumber,
    required this.vehicleType,
    required this.status,
    required this.owner,
    required this.entryTime,
    required this.location,
    required this.exitTime,
  });

  factory ExitPanelCard.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return ExitPanelCard(
      plateNumber: (json['PlateNumber'] as String?) ?? (json['plateNumber'] as String?) ?? '-',
      vehicleType: (json['VehicleType'] as String?) ?? (json['vehicleType'] as String?) ?? '-',
      status: (json['StatusText'] as String?) ?? (json['Status'] as String?) ?? (json['status'] as String?) ?? 'Çıkış Yapıldı',
      owner: (json['OwnerName'] as String?) ?? (json['Owner'] as String?) ?? (json['owner'] as String?) ?? '-',
      entryTime: parseDate(json['CheckInTime'] ?? json['EntryTime'] ?? json['entryTime']),
      location: (json['ParkingLot'] as String?) ?? (json['Location'] as String?) ?? (json['location'] as String?) ?? '-',
      exitTime: parseDate(json['CheckOutTime'] ?? json['ExitTime'] ?? json['exitTime']),
    );
  }
}
