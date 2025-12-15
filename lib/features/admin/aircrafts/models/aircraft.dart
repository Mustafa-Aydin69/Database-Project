class Aircraft {
  final int aircraftId;
  final int? airlineId;
  final String model;
  final int capacity;
  Aircraft({
    required this.aircraftId,
    required this.airlineId,
    required this.model,
    required this.capacity,
  });
  factory Aircraft.fromJson(Map<String, dynamic> json) {
    return Aircraft(
      aircraftId: (json['aircraftId'] as num?)?.toInt() ?? 0,
      airlineId: json['airlineId'] == null ? null : (json['airlineId'] as num?)?.toInt(),
      model: (json['model'] as String?) ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
    );
  }
}
