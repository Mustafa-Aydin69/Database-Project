import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../models/exit_panel_card.dart';

class ExitPanelCardsApi {
  static String get baseUrl {
    // Flutter Web hedefi için localhost:3000 kullan
    if (kIsWeb) return 'http://localhost:3000/api';
    // Diğer platformlar için de varsayılan olarak localhost:3000
    return 'http://localhost:3000/api';
  }

  static Future<List<ExitPanelCard>> fetch() async {
    final url = Uri.parse('$baseUrl/parking/exit-panel-cards');
    final res = await http.get(url);
    debugPrint('EXIT_PANEL_STATUS=${res.statusCode}');
    debugPrint('EXIT_PANEL_RAW=${res.body}');
    if (res.statusCode == 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        final items = (body['data'] as List?) ?? [];
        final parsed = items.map((e) => ExitPanelCard.fromJson(e as Map<String, dynamic>)).toList();
        debugPrint('EXIT_PANEL_FIRST_ITEM=${parsed.isNotEmpty ? parsed.first.toString() : 'EMPTY'}');
        return parsed;
      }
      throw Exception(body['message'] ?? 'İstek başarısız');
    }
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }
}
