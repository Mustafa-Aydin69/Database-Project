class TerminalSummary {
  final String terminalCode;
  final int totalSpots;
  final int emptyCount;
  final int occupiedCount;
  final int reservedCount;
  final int maintenanceCount;
  TerminalSummary({
    required this.terminalCode,
    required this.totalSpots,
    required this.emptyCount,
    required this.occupiedCount,
    required this.reservedCount,
    required this.maintenanceCount,
  });
  factory TerminalSummary.fromJson(Map<String, dynamic> json) {
    return TerminalSummary(
      terminalCode: (json['terminalCode'] as String?) ?? '',
      totalSpots: (json['totalSpots'] as num?)?.toInt() ?? 0,
      emptyCount: (json['emptyCount'] as num?)?.toInt() ?? 0,
      occupiedCount: (json['occupiedCount'] as num?)?.toInt() ?? 0,
      reservedCount: (json['reservedCount'] as num?)?.toInt() ?? 0,
      maintenanceCount: (json['maintenanceCount'] as num?)?.toInt() ?? 0,
    );
  }
}
