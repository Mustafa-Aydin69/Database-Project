class ParkingLotOccupancy {
  final String lotName;
  final double occupancyRate;
  ParkingLotOccupancy({required this.lotName, required this.occupancyRate});
  factory ParkingLotOccupancy.fromJson(Map<String, dynamic> json) {
    return ParkingLotOccupancy(
      lotName: (json['lotName'] as String?) ?? '',
      occupancyRate: (json['occupancyRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
