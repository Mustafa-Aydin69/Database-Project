import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/airline.dart';

class AirlinesApi {
  static final List<Uri> _candidates = [
    Uri.parse('http://localhost:3000/api/admin/flight-management/airlines'),
    Uri.parse('http://10.0.2.2:3000/api/admin/flight-management/airlines'),
  ];

  static Future<List<Airline>> fetchAirlines() async {
    Exception? last;
    for (final url in _candidates) {
      try {
        final res = await http.get(url);
        if (res.statusCode == 200) {
          final body = json.decode(res.body) as Map<String, dynamic>;
          final items = (body['data'] as List?) ?? [];
          return items.map((e) => Airline.fromJson(e as Map<String, dynamic>)).toList();
        } else {
          last = Exception('HTTP ${res.statusCode}: ${res.body}');
        }
      } catch (e) {
        last = Exception('Network error: $e');
      }
    }
    throw last ?? Exception('Failed to fetch airlines.');
  }

  static Future<Airline> updateAirline({
    required int airlineId,
    required String name,
    required String country,
    required String contact,
  }) async {
    Exception? last;
    for (final base in _candidates) {
      try {
        final url = Uri.parse('${base.toString()}/$airlineId');
        final res = await http.put(url, headers: {'Content-Type': 'application/json'}, body: json.encode({
          'name': name,
          'country': country,
          'contact': contact,
        }));
        if (res.statusCode == 200) {
          final body = json.decode(res.body) as Map<String, dynamic>;
          final data = body['data'] as Map<String, dynamic>;
          return Airline.fromJson(data);
        } else {
          last = Exception('HTTP ${res.statusCode}: ${res.body}');
        }
      } catch (e) {
        last = Exception('Network error: $e');
      }
    }
    throw last ?? Exception('Failed to update airline.');
  }

  static Future<Airline> addAirline({
    required String name,
    required String country,
    required String contact,
  }) async {
    Exception? last;
    for (final base in _candidates) {
      try {
        final url = base;
        final res = await http.post(url, headers: {'Content-Type': 'application/json'}, body: json.encode({
          'name': name,
          'country': country,
          'contact': contact,
        }));
        if (res.statusCode == 200) {
          final body = json.decode(res.body) as Map<String, dynamic>;
          final data = body['data'] as Map<String, dynamic>;
          return Airline.fromJson(data);
        } else {
          last = Exception('HTTP ${res.statusCode}: ${res.body}');
        }
      } catch (e) {
        last = Exception('Network error: $e');
      }
    }
    throw last ?? Exception('Failed to add airline.');
  }

  static Future<void> deleteAirline(int airlineId) async {
    Exception? last;
    for (final base in _candidates) {
      try {
        final url = Uri.parse('${base.toString()}/$airlineId');
        final res = await http.delete(url);
        if (res.statusCode == 200) {
          return;
        } else {
          last = Exception('HTTP ${res.statusCode}: ${res.body}');
        }
      } catch (e) {
        last = Exception('Network error: $e');
      }
    }
    throw last ?? Exception('Failed to delete airline.');
  }
}
