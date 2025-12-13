import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Check-in istatistik özet modeli
class CheckInSummary {
  final int todayCheckInCount;
  final int completedCheckInCount;
  final int pendingCheckInCount;
  final int cancelledCheckInCount;

  CheckInSummary({
    required this.todayCheckInCount,
    required this.completedCheckInCount,
    required this.pendingCheckInCount,
    required this.cancelledCheckInCount,
  });

  factory CheckInSummary.fromJson(Map<String, dynamic> json) {
    return CheckInSummary(
      todayCheckInCount: json['todayCheckInCount'] ?? 0,
      completedCheckInCount: json['completedCheckInCount'] ?? 0,
      pendingCheckInCount: json['pendingCheckInCount'] ?? 0,
      cancelledCheckInCount: json['cancelledCheckInCount'] ?? 0,
    );
  }

  /// Varsayılan (boş) özet oluştur
  factory CheckInSummary.empty() {
    return CheckInSummary(
      todayCheckInCount: 0,
      completedCheckInCount: 0,
      pendingCheckInCount: 0,
      cancelledCheckInCount: 0,
    );
  }
}

/// Son tamamlanan check-in işlemi modeli
class LastCompletedCheckIn {
  final String reservationNo;
  final String passengerName;
  final dynamic flightNo; // int veya string olabilir
  final String route;
  final String status;
  final String checkInTime;

  LastCompletedCheckIn({
    required this.reservationNo,
    required this.passengerName,
    required this.flightNo,
    required this.route,
    required this.status,
    required this.checkInTime,
  });

  factory LastCompletedCheckIn.fromJson(Map<String, dynamic> json) {
    return LastCompletedCheckIn(
      reservationNo: json['ReservationNo'] as String? ?? '',
      passengerName: json['PassengerName'] as String? ?? '',
      flightNo: json['FlightNo'] ?? '',
      route: json['Route'] as String? ?? '',
      status: json['Status'] as String? ?? 'Tamamlanan',
      checkInTime: json['CheckInTime'] as String? ?? '',
    );
  }
}

class CheckInService {
  // Singleton yapısı
  static final CheckInService _instance = CheckInService._internal();
  factory CheckInService() => _instance;
  CheckInService._internal();

  // ⚠️ API Adresi: Chrome/Web uygulaması için localhost kullanılmalıdır.
  static const String _summaryApiUrl =
      'http://localhost:3000/api/checkin/summary-today';
  static const String _lastCompletedApiUrl =
      'http://localhost:3000/api/checkin/last-completed-today';
  // Mobil (Android Emülatörü) için: 'http://10.0.2.2:3000/api/checkin/...'
  // Mobil (Gerçek Cihaz) için: Bilgisayarınızın yerel IP adresi.

  /// Bugünkü check-in özet istatistiklerini getirir
  /// Başarılıysa CheckInSummary, başarısızsa null döner
  Future<CheckInSummary?> getTodaySummary() async {
    try {
      final response = await http.get(
        Uri.parse(_summaryApiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // API'den gelen data'yı CheckInSummary modeline dönüştür
        final data = responseBody['data'] as Map<String, dynamic>?;
        debugPrint('📥 Check-in API raw data: $data');
        if (data != null) {
          return CheckInSummary.fromJson(data);
        }
      }

      // Hata durumunda varsayılan değerler döndür
      debugPrint('⚠️ Check-in summary API hatası: ${response.statusCode}');
      return CheckInSummary.empty();
    } catch (e) {
      // Ağ bağlantısı hatası
      debugPrint('❌ Check-in summary HTTP hatası: $e');
      // Hata durumunda varsayılan değerler döndür
      return CheckInSummary.empty();
    }
  }

  /// Bugünkü tamamlanan son check-in işlemlerini getirir
  /// Başarılıysa LastCompletedCheckIn listesi, başarısızsa boş liste döner
  Future<List<LastCompletedCheckIn>> getLastCompletedCheckInsToday() async {
    try {
      final response = await http.get(
        Uri.parse(_lastCompletedApiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // API'den gelen data'yı LastCompletedCheckIn listesine dönüştür
        final data = responseBody['data'] as List<dynamic>?;
        debugPrint('📥 Last completed check-ins API raw data: $data');
        if (data != null) {
          return data
              .map((item) => LastCompletedCheckIn.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }

      // Hata durumunda boş liste döndür
      debugPrint('⚠️ Last completed check-ins API hatası: ${response.statusCode}');
      return [];
    } catch (e) {
      // Ağ bağlantısı hatası
      debugPrint('❌ Last completed check-ins HTTP hatası: $e');
      // Hata durumunda boş liste döndür
      return [];
    }
  }
}
