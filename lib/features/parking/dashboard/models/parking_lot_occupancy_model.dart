class ParkingLotOccupancyModel {
  final String parkingLotName;
  final int totalSpots;
  final int occupiedSpots;
  final int freeSpots;
  final double occupancyRate; // 0..100 or 0..1 based on API

  ParkingLotOccupancyModel({
    required this.parkingLotName,
    required this.totalSpots,
    required this.occupiedSpots,
    required this.freeSpots,
    required this.occupancyRate,
  });

  factory ParkingLotOccupancyModel.fromJson(Map<String, dynamic> json) {
    return ParkingLotOccupancyModel(
      parkingLotName: (json['parkingLotName'] as String?) ?? '',
      totalSpots: (json['totalSpots'] as num?)?.toInt() ?? 0,
      occupiedSpots: (json['occupiedSpots'] as num?)?.toInt() ?? 0,
      freeSpots: (json['freeSpots'] as num?)?.toInt() ?? 0,
      occupancyRate: (json['occupancyRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

