import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/exit_popup_info_model.dart';
import 'package:proje/core/services/auth_service.dart';

class ParkingApiService {
  static final List<String> _baseCandidates = [
    'http://localhost:3001/api',
    'http://localhost:3000/api',
    'http://10.0.2.2:3000/api',
  ];

  static Future<Map<String, dynamic>> _getJson(String path) async {
    Exception? lastError;
    for (final base in _baseCandidates) {
      try {
        final url = Uri.parse('$base$path');
        final res = await http.get(url);
        if (res.statusCode == 200) {
          return json.decode(res.body) as Map<String, dynamic>;
        } else {
          lastError = Exception('HTTP ${res.statusCode} from ${url.host}: ${res.body}');
        }
      } catch (e) {
        lastError = Exception('Network error: $e');
      }
    }
    throw lastError ?? Exception('Request failed');
  }

  static Future<Map<String, dynamic>> _postJson(String path, Map<String, dynamic> payload, {Map<String, String>? headers}) async {
    Exception? lastError;
    final hdrs = {'Content-Type': 'application/json', ...?headers};
    for (final base in _baseCandidates) {
      try {
        final url = Uri.parse('$base$path');
        final res = await http.post(url, headers: hdrs, body: json.encode(payload));
        if (res.statusCode == 200 || res.statusCode == 400) {
          return json.decode(res.body) as Map<String, dynamic>;
        } else {
          lastError = Exception('HTTP ${res.statusCode} from ${url.host}: ${res.body}');
        }
      } catch (e) {
        lastError = Exception('Network error: $e');
      }
    }
    throw lastError ?? Exception('Request failed');
  }

  static Future<ExitPopupInfo> getExitPopupInfo(String plateNumber) async {
    final body = await _getJson('/parking/exit-popup-info?plateNumber=$plateNumber');
    if (body['success'] == true) {
      return ExitPopupInfo.fromJson(body);
    }
    throw Exception(body['message'] ?? 'İstek başarısız');
  }

  static Future<List<Map<String, dynamic>>> getVehicleTypes() async {
    final body = await _getJson('/parking/vehicle-types');
    if (body['success'] == true) {
      final data = (body['data'] as List?) ?? [];
      return data
          .map((e) {
            final m = (e as Map<String, dynamic>);
            final rawId = m['typeID'] ?? m['typeId'];
            int? id;
            if (rawId is num) {
              id = rawId.toInt();
            } else if (rawId is String) {
              final parsed = int.tryParse(rawId);
              id = parsed;
            }
            return {
              'typeId': id,
              'typeName': (m['typeName'] as String?) ?? '',
            };
          })
          .where((m) => m['typeId'] != null)
          .toList();
    }
    throw Exception(body['message'] ?? 'İstek başarısız');
  }

  static Future<void> checkoutVehicle({
    required String plateNumber,
    required double amount,
    required String paymentMethod,
    int? actorUserId,
  }) async {
    final payload = {
      'plateNumber': plateNumber,
      'amount': amount,
      'paymentMethod': paymentMethod,
      if (actorUserId != null) 'actorUserId': actorUserId,
    };
    final body = await _postJson('/parking/checkout', payload);
    if (body['success'] == true) {
      return;
    }
    throw Exception(body['message'] ?? 'İstek başarısız');
  }

  static Future<Map<String, dynamic>> createParkingEntry({
    required String plateNumber,
    required int typeId,
    required String ownerFullName,
    required String ownerPhone,
    required int parkingLotId,
    required String spotNumber,
  }) async {
    final payload = {
      'plateNumber': plateNumber,
      'typeId': typeId,
      'ownerFullName': ownerFullName,
      'ownerPhone': ownerPhone,
      'parkingLotId': parkingLotId,
      'spotNumber': spotNumber,
    };
    final currentUserId = AuthService().currentUserId;
    final headers = {
      if (currentUserId != null) 'x-user-id': currentUserId.toString(),
    };
    final body = await _postJson('/parking/entry', payload, headers: headers);
    if (body['success'] == true) {
      return body['data'] as Map<String, dynamic>;
    }
    final code = body['code'];
    final msg = body['errorMessage'] ?? body['message'] ?? 'İstek başarısız';
    throw Exception(code != null ? '$code: $msg' : msg);
  }
}
