import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../models/vehicle_type_item.dart';

class VehicleTypesApi {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api';
    return 'http://localhost:3000/api';
  }

  static Future<List<VehicleTypeItem>> fetch() async {
    final url = Uri.parse('$baseUrl/parking/vehicle-types');
    final res = await http.get(url);
    debugPrint('VEHICLE_TYPES_STATUS=${res.statusCode}');
    debugPrint('VEHICLE_TYPES_RAW=${res.body}');
    if (res.statusCode == 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        final items = (body['data'] as List?) ?? [];
        return items.map((e) => VehicleTypeItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception(body['message'] ?? 'İstek başarısız');
    }
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }
}
