class ParkingLotSummary {
  final int parkingLotId;
  final String lotName;
  final int totalSpots;
  final int emptyCount;
  final int occupiedCount;
  final int reservedCount;
  final int maintenanceCount;
  ParkingLotSummary({
    required this.parkingLotId,
    required this.lotName,
    required this.totalSpots,
    required this.emptyCount,
    required this.occupiedCount,
    required this.reservedCount,
    required this.maintenanceCount,
  });
  factory ParkingLotSummary.fromJson(Map<String, dynamic> json) {
    return ParkingLotSummary(
      parkingLotId: (json['parkingLotId'] as num).toInt(),
      lotName: (json['lotName'] as String?) ?? '',
      totalSpots: (json['totalSpots'] as num?)?.toInt() ?? 0,
      emptyCount: (json['emptyCount'] as num?)?.toInt() ?? 0,
      occupiedCount: (json['occupiedCount'] as num?)?.toInt() ?? 0,
      reservedCount: (json['reservedCount'] as num?)?.toInt() ?? 0,
      maintenanceCount: (json['maintenanceCount'] as num?)?.toInt() ?? 0,
    );
  }
}
