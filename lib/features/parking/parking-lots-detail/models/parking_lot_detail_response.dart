import 'parking_lot_summary.dart';
import 'terminal_summary.dart';
import 'parking_spot.dart';

class ParkingLotDetailResponse {
  final ParkingLotSummary summary;
  final List<TerminalSummary> terminals;
  final List<ParkingSpot> spots;
  ParkingLotDetailResponse({
    required this.summary,
    required this.terminals,
    required this.spots,
  });
  factory ParkingLotDetailResponse.fromJson(Map<String, dynamic> json) {
    return ParkingLotDetailResponse(
      summary: ParkingLotSummary.fromJson(json['summary'] as Map<String, dynamic>),
      terminals: ((json['terminals'] as List?) ?? [])
          .map((e) => TerminalSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      spots: ((json['spots'] as List?) ?? [])
          .map((e) => ParkingSpot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
