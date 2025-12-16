class AirlineOption {
  final int airlineId;
  final String airlineName;
  AirlineOption({required this.airlineId, required this.airlineName});
  factory AirlineOption.fromJson(Map<String, dynamic> json) {
    return AirlineOption(
      airlineId: (json['airlineId'] as num?)?.toInt() ?? 0,
      airlineName: (json['airlineName'] as String?) ?? '',
    );
  }
}
