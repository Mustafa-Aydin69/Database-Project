import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/dashboard_kpi_model.dart';

class ParkingDashboardApi {
  static Future<DashboardKpiModel> fetchKpi() async {
    final urls = [
      Uri.parse('http://localhost:3000/api/parking/kpi-cards'),
      Uri.parse('http://10.0.2.2:3000/api/parking/kpi-cards'),
    ];

    Exception? lastError;
    for (final url in urls) {
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body) as Map<String, dynamic>;
          return DashboardKpiModel.fromJson(jsonData);
        } else {
          lastError = Exception('Failed (${response.statusCode}) from ${url.host}: ${response.body}');
        }
      } catch (e) {
        lastError = Exception('Network error from ${url.host}: $e');
      }
    }

    throw lastError ?? Exception('Unknown error fetching KPI');
  }
}

