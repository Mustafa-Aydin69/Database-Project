class Airline {
  final int airlineId;
  final String name;
  final String country;
  final String contact;
  Airline({
    required this.airlineId,
    required this.name,
    required this.country,
    required this.contact,
  });
  factory Airline.fromJson(Map<String, dynamic> json) {
    return Airline(
      airlineId: (json['airlineId'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      country: (json['country'] as String?) ?? '',
      contact: (json['contact'] as String?) ?? '',
    );
  }
}
