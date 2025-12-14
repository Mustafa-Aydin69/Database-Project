import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/parking_lot_detail_response.dart';

class ParkingLotDetailApi {
  static final List<String> _bases = [
    'http://localhost:3000/api',
    'http://10.0.2.2:3000/api',
  ];

  static Future<ParkingLotDetailResponse> fetchDetail(int parkingLotId) async {
    Exception? last;
    for (final base in _bases) {
      try {
        final url = Uri.parse('$base/parking/parking-lots/$parkingLotId/detail');
        final res = await http.get(url);
        if (res.statusCode == 200) {
          final jsonMap = json.decode(res.body) as Map<String, dynamic>;
          return ParkingLotDetailResponse.fromJson(jsonMap);
        } else if (res.statusCode == 404) {
          throw Exception('Kayıt bulunamadı');
        } else {
          last = Exception('HTTP ${res.statusCode}: ${res.body}');
        }
      } catch (e) {
        last = Exception('Network error: $e');
      }
    }
    throw last ?? Exception('Request failed');
  }
}
