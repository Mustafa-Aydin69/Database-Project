class Airport {
  final int airportId;
  final String name;
  final String city;
  final String country;
  final String iataCode;
  Airport({
    required this.airportId,
    required this.name,
    required this.city,
    required this.country,
    required this.iataCode,
  });
  factory Airport.fromJson(Map<String, dynamic> json) {
    return Airport(
      airportId: (json['airportId'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      city: (json['city'] as String?) ?? '',
      country: (json['country'] as String?) ?? '',
      iataCode: (json['iataCode'] as String?) ?? '',
    );
  }
}
