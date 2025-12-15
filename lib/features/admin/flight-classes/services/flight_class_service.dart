import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/flight_class.dart';

class FlightClassService {
  static final List<Uri> _candidates = [
    Uri.parse('http://10.0.2.2:3000/api/flight-classes'),
    Uri.parse('http://localhost:3000/api/flight-classes'),
  ];

  static Future<List<FlightClass>> getFlightClasses() async {
    Exception? last;
    for (final url in _candidates) {
      try {
        final res = await http.get(url);
        if (res.statusCode == 200) {
          final data = json.decode(res.body) as List<dynamic>;
          return data
              .map((e) => FlightClass.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          last = Exception('HTTP ${res.statusCode}: ${res.body}');
        }
      } catch (e) {
        last = Exception('Network error: $e');
      }
    }
    throw last ?? Exception('Failed to fetch flight classes');
  }

  static Future<FlightClass> updateFlightClass({
    required int classId,
    required String className,
    required String description,
  }) async {
    Exception? last;
    for (final base in _candidates) {
      try {
        final url = Uri.parse('${base.toString()}/$classId');
        final res = await http.put(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'className': className,
            'description': description,
          }),
        );
        if (res.statusCode == 200) {
          final body = json.decode(res.body) as Map<String, dynamic>;
          return FlightClass.fromJson(body);
        } else {
          String msg = 'Sunucu hatası. Daha sonra tekrar deneyin.';
          Map<String, dynamic>? details;
          try {
            final body = json.decode(res.body) as Map<String, dynamic>;
            msg = (body['message'] as String?) ?? msg;
            details = (body['details'] as Map?)?.cast<String, dynamic>();
          } catch (_) {}
          if (res.statusCode == 404 && msg == 'Sunucu hatası. Daha sonra tekrar deneyin.') {
            msg = 'Sınıf bulunamadı.';
          }
          if (!kReleaseMode && details != null) {
            debugPrint('UpdateFlightClass error details: $details');
          }
          throw Exception(msg);
        }
      } catch (e) {
        last = Exception(e.toString());
      }
    }
    throw last ?? Exception('Sunucu hatası. Daha sonra tekrar deneyin.');
  }

  static Future<FlightClass> createFlightClass({
    required String className,
    required String description,
  }) async {
    Exception? last;
    for (final base in _candidates) {
      try {
        final url = base;
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'className': className,
            'description': description,
          }),
        );
        if (res.statusCode == 200) {
          final body = json.decode(res.body) as Map<String, dynamic>;
          return FlightClass.fromJson(body);
        } else {
          String msg = 'Sunucu hatası. Daha sonra tekrar deneyin.';
          Map<String, dynamic>? details;
          try {
            final body = json.decode(res.body) as Map<String, dynamic>;
            msg = (body['message'] as String?) ?? msg;
            details = (body['details'] as Map?)?.cast<String, dynamic>();
          } catch (_) {}
          if (!kReleaseMode && details != null) {
            debugPrint('CreateFlightClass error details: $details');
          }
          throw Exception(msg);
        }
      } catch (e) {
        last = Exception(e.toString());
      }
    }
    throw last ?? Exception('Sunucu hatası. Daha sonra tekrar deneyin.');
  }

  static Future<Map<String, dynamic>> deleteFlightClass(int classId) async {
    Exception? last;
    for (final base in _candidates) {
      try {
        final url = Uri.parse('${base.toString()}/$classId');
        final res = await http.delete(url);
        if (res.statusCode == 200) {
          final body = json.decode(res.body) as Map<String, dynamic>;
          return body;
        } else {
          String msg = 'Silme başarısız. Daha sonra tekrar deneyin.';
          Map<String, dynamic>? details;
          try {
            final body = json.decode(res.body) as Map<String, dynamic>;
            msg = (body['message'] as String?) ?? msg;
            details = (body['details'] as Map?)?.cast<String, dynamic>();
          } catch (_) {}
          if (!kReleaseMode && details != null) {
            debugPrint('DeleteFlightClass error details: $details');
          }
          throw Exception(msg);
        }
      } catch (e) {
        last = Exception(e.toString());
      }
    }
    throw last ?? Exception('Silme başarısız. Daha sonra tekrar deneyin.');
  }
}
