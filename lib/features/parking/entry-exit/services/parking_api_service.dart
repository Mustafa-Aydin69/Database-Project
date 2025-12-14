import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../models/exit_popup_info_model.dart';

class ParkingApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    if (Platform.isIOS) return 'http://localhost:3000/api';
    return 'http://localhost:3000/api';
  }

  static Future<ExitPopupInfo> getExitPopupInfo(String plateNumber) async {
    final url = Uri.parse('$baseUrl/parking/exit-popup-info?plateNumber=$plateNumber');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      final success = body['success'] == true;
      if (success) {
        return ExitPopupInfo.fromJson(body);
      }
      throw Exception(body['message'] ?? 'İstek başarısız');
    }
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }

  static Future<void> checkoutVehicle({
    required String plateNumber,
    required double amount,
    required String paymentMethod,
    int? actorUserId,
  }) async {
    final url = Uri.parse('$baseUrl/parking/checkout');
    final payload = {
      'plateNumber': plateNumber,
      'amount': amount,
      'paymentMethod': paymentMethod,
      if (actorUserId != null) 'actorUserId': actorUserId,
    };
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );
    if (res.statusCode == 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return;
      }
      throw Exception(body['message'] ?? 'İstek başarısız');
    }
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }
}
