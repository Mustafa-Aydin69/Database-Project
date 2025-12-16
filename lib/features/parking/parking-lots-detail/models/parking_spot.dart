class ParkingSpot {
  final int spotId;
  final int parkingLotId;
  final String terminalCode;
  final String spotNumber;
  final String spotStatus;
  final int isReserved;
  ParkingSpot({
    required this.spotId,
    required this.parkingLotId,
    required this.terminalCode,
    required this.spotNumber,
    required this.spotStatus,
    required this.isReserved,
  });
  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    final isResNum = (json['isReserved'] as num?)?.toInt() ?? 0;
    final isReserved = isResNum == 1 ? 1 : 0;
    final raw = (json['spotStatus'] ?? '').toString().toUpperCase().trim();
    final spotStatus = (raw == 'EMPTY' || raw == 'OCCUPIED')
        ? raw
        : (isReserved == 1 ? 'OCCUPIED' : 'EMPTY');
    return ParkingSpot(
      spotId: (json['spotId'] as num?)?.toInt() ?? 0,
      parkingLotId: (json['parkingLotId'] as num?)?.toInt() ?? 0,
      terminalCode: (json['terminalCode'] as String?) ?? '',
      spotNumber: (json['spotNumber'] as String?) ?? '',
      spotStatus: spotStatus,
      isReserved: isReserved,
    );
  }
}
