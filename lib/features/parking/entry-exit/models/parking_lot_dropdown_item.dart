class ParkingLotDropdownItem {
  final int parkingLotID;
  final String lotName;
  ParkingLotDropdownItem({required this.parkingLotID, required this.lotName});
  factory ParkingLotDropdownItem.fromJson(Map<String, dynamic> json) {
    return ParkingLotDropdownItem(
      parkingLotID: (json['parkingLotID'] as num).toInt(),
      lotName: (json['lotName'] as String?) ?? '',
    );
  }
  @override
  String toString() => '($parkingLotID) $lotName';
}
