class ExitPopupInfo {
  final String plateNumber;
  final String ownerName;
  final DateTime checkInTime;
  final int durationMinutes;
  final double amount;
  ExitPopupInfo({
    required this.plateNumber,
    required this.ownerName,
    required this.checkInTime,
    required this.durationMinutes,
    required this.amount,
  });
  factory ExitPopupInfo.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map?) ?? json;
    final plate = (data['plateNumber'] as String?) ?? '';
    final owner = (data['ownerName'] as String?) ?? '';
    final checkInRaw = data['checkInTime'];
    final checkIn = DateTime.parse(checkInRaw as String);
    final duration = (data['durationMinutes'] as num?)?.toInt() ?? 0;
    final amountVal = (data['amount'] as num?)?.toDouble() ?? 0.0;
    return ExitPopupInfo(
      plateNumber: plate,
      ownerName: owner,
      checkInTime: checkIn,
      durationMinutes: duration,
      amount: amountVal,
    );
  }
}
