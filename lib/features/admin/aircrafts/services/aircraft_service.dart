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
          return data.map((e) => Aircraft.fromJson(e as Map<String, dynamic>)).toList();
        } else {
          last = Exception('HTTP ${res.statusCode}: ${res.body}');
        }
      } catch (e) {
        last = Exception('Network error: $e');
      }
    }
    throw last ?? Exception('Failed to fetch aircrafts.');
  }
}
