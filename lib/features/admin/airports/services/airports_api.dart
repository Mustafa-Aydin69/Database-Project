import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/airport.dart';

class AirportsApi {
  static final List<Uri> _candidates = [
    Uri.parse('http://localhost:3000/api/admin/flight-management/airports'),
    Uri.parse('http://10.0.2.2:3000/api/admin/flight-management/airports'),
  ];

  static Future<List<Airport>> fetchAirports() async {
    Exception? last;
    for (final url in _candidates) {
      try {
        final res = await http.get(url);
        if (res.statusCode == 200) {
          final body = json.decode(res.body) as Map<String, dynamic>;
          final items = (body['data'] as List?) ?? [];
          return items.map((e) => Airport.fromJson(e as Map<String, dynamic>)).toList();
        } else {
          last = Exception('HTTP ${res.statusCode}: ${res.body}');
        }
      } catch (e) {
        last = Exception('Network error: $e');
      }
    }
    throw last ?? Exception('Failed to fetch airports.');
  }

  static Future<Airport> updateAirport({
    required int airportId,
    required String name,
    required String city,
    required String country,
    required String iataCode,
  }) async {
    Exception? last;
    for (final base in _candidates) {
      try {
        final url = Uri.parse('${base.toString()}/$airportId');
        final res = await http.put(url, headers: {'Content-Type': 'application/json'}, body: json.encode({
          'name': name,
          'city': city,
          'country': country,
          'iataCode': iataCode,
        }));
        if (res.statusCode == 200) {
          final body = json.decode(res.body) as Map<String, dynamic>;
          final data = body['data'] as Map<String, dynamic>;
          return Airport.fromJson(data);
        } else {
          last = Exception('HTTP ${res.statusCode}: ${res.body}');
        }
      } catch (e) {
        last = Exception('Network error: $e');
      }
    }
    throw last ?? Exception('Failed to update airport.');
  }

  static Future<Airport> addAirport({
    required String name,
    required String city,
    required String country,
    required String iataCode,
  }) async {
    Exception? last;
    for (final base in _candidates) {
      try {
        final url = base;
        final res = await http.post(url, headers: {'Content-Type': 'application/json'}, body: json.encode({
          'name': name,
          'city': city,
          'country': country,
          'iataCode': iataCode,
        }));
        if (res.statusCode == 200) {
          final body = json.decode(res.body) as Map<String, dynamic>;
          final data = body['data'] as Map<String, dynamic>;
          return Airport.fromJson(data);
        } else {
          last = Exception('HTTP ${res.statusCode}: ${res.body}');
        }
      } catch (e) {
        last = Exception('Network error: $e');
      }
    }
    throw last ?? Exception('Failed to add airport.');
  }

  static Future<void> deleteAirport(int airportId) async {
    Exception? last;
    for (final base in _candidates) {
      try {
        final url = Uri.parse('${base.toString()}/$airportId');
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
    throw last ?? Exception('Failed to close airport.');
  }
}
