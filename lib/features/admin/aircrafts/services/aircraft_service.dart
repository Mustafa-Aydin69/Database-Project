import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/aircraft.dart';

class AircraftService {
  static final List<Uri> _candidates = [
    Uri.parse('http://10.0.2.2:3000/api/aircrafts'),
    Uri.parse('http://localhost:3000/api/aircrafts'),
  ];

  static Future<List<Aircraft>> getAircrafts() async {
    Exception? last;
    for (final url in _candidates) {
      try {
        final res = await http.get(url);
        if (res.statusCode == 200) {
          final data = json.decode(res.body) as List<dynamic>;
          final list = data.map((e) => Aircraft.fromJson(e as Map<String, dynamic>)).toList();
          return list.where((a) => a.status == 'Active').toList();
        } else {
          last = Exception('HTTP ${res.statusCode}: ${res.body}');
        }
      } catch (e) {
        last = Exception('Network error: $e');
      }
    }
    throw last ?? Exception('Failed to fetch aircrafts.');
  }

  static Future<Aircraft> softDeleteAircraft(int aircraftId) async {
    Exception? last;
    for (final base in _candidates) {
      try {
        final url = Uri.parse('${base.toString()}/$aircraftId/soft-delete');
        final res = await http.patch(url);
        if (res.statusCode == 200) {
          final body = json.decode(res.body) as Map<String, dynamic>;
          return Aircraft.fromJson(body);
        } else {
          String msg = 'Sunucu hatası. Daha sonra tekrar deneyin.';
          try {
            final body = json.decode(res.body) as Map<String, dynamic>;
            msg = (body['message'] as String?) ?? msg;
          } catch (_) {}
          if (res.statusCode == 400) {
            throw Exception(msg);
          }
          throw Exception('Sunucu hatası. Daha sonra tekrar deneyin.');
        }
      } catch (e) {
        last = Exception(e.toString());
      }
    }
    throw last ?? Exception('Sunucu hatası. Daha sonra tekrar deneyin.');
  }
}
