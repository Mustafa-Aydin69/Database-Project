class DashboardKpiModel {
  final int totalSpots;
  final int occupiedSpots;
  final int freeSpots;
  final int activeReservations;

  DashboardKpiModel({
    required this.totalSpots,
    required this.occupiedSpots,
    required this.freeSpots,
    required this.activeReservations,
  });

  factory DashboardKpiModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return DashboardKpiModel(
      totalSpots: (data['totalSpots'] as num?)?.toInt() ?? 0,
      occupiedSpots: (data['occupiedSpots'] as num?)?.toInt() ?? 0,
      freeSpots: (data['freeSpots'] as num?)?.toInt() ?? 0,
      activeReservations: (data['activeReservations'] as num?)?.toInt() ?? 0,
    );
  }
}

