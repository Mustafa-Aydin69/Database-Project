class FlightClass {
  final int classId;
  final String className;
  final String description;
  FlightClass({
    required this.classId,
    required this.className,
    required this.description,
  });
  factory FlightClass.fromJson(Map<String, dynamic> json) {
    return FlightClass(
      classId: (json['classId'] as num?)?.toInt() ?? 0,
      className: (json['className'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
    );
  }
}
