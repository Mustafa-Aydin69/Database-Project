class RecentCheckout {
  final String plateNumber;
  final int durationMinutes;
  final DateTime checkOutTime;
  final double amount;

  RecentCheckout({
    required this.plateNumber,
    required this.durationMinutes,
    required this.checkOutTime,
    required this.amount,
  });

  factory RecentCheckout.fromJson(Map<String, dynamic> json) {
    return RecentCheckout(
      plateNumber: (json['plateNumber'] as String?) ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      checkOutTime: DateTime.parse(json['checkOutTime'] as String),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

