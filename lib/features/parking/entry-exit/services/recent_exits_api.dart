import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/exit_vehicle_model.dart';

class RecentExitsApi {
  static Future<List<ExitVehicleModel>> fetchRecentExits({int topN = 20}) async {
    final urls = [
      Uri.parse('http://localhost:3000/api/parking/recent-checkouts-v2?topN=$topN'),
      Uri.parse('http://10.0.2.2:3000/api/parking/recent-checkouts-v2?topN=$topN'),
    ];
    Exception? lastError;
    for (final url in urls) {
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body) as Map<String, dynamic>;
          final List<dynamic> items = (jsonData['data'] as List?) ?? [];
          return items
              .map((e) => ExitVehicleModel.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          lastError = Exception('Failed (${response.statusCode}) from ${url.host}: ${response.body}');
        }
      } catch (e) {
        lastError = Exception('Network error from ${url.host}: $e');
      }
    }
    throw lastError ?? Exception('Unknown error fetching recent exits');
  }
}
