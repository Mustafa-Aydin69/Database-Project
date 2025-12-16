class VehicleTypeItem {
  final int typeId;
  final String typeName;
  VehicleTypeItem({required this.typeId, required this.typeName});
  factory VehicleTypeItem.fromJson(Map<String, dynamic> json) {
    return VehicleTypeItem(
      typeId: (json['typeId'] as num).toInt(),
      typeName: (json['typeName'] as String?) ?? '',
    );
  }
  @override
  String toString() => '($typeId) $typeName';
}
