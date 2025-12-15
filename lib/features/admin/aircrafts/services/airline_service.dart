import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/airline_option.dart';

class AirlineService {
  static List<AirlineOption>? _cache;
  static final List<Uri> _candidates = [
    Uri.parse('http://10.0.2.2:3000/api/airlines'),
    Uri.parse('http://localhost:3000/api/airlines'),
  ];

  static Future<List<AirlineOption>> getAirlines({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) return _cache!;
    Exception? last;
    for (final url in _candidates) {
      try {
        final res = await http.get(url);
        if (res.statusCode == 200) {
          final data = json.decode(res.body) as List<dynamic>;
          final list = data.map((e) => AirlineOption.fromJson(e as Map<String, dynamic>)).toList();
          _cache = list;
          return list;
        } else {
          last = Exception('HTTP ${res.statusCode}: ${res.body}');
        }
      } catch (e) {
        last = Exception('Network error: $e');
      }
    }
    throw last ?? Exception('Failed to fetch airlines.');
  }
}
