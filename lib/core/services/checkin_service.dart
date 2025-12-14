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

/// Check-in bilet modeli
class CheckInTicket {
  final String reservationNo;
  final String passengerName;
  final String passportNo; // "Pasaport girilmedi" olabilir
  final String route;
  final String reservationDate; // "YYYY-MM-DD · HH:mm" formatında
  final String seatInfo;
  final String status; // "Bekleyen" veya "Tamamlanan"

  CheckInTicket({
    required this.reservationNo,
    required this.passengerName,
    required this.passportNo,
    required this.route,
    required this.reservationDate,
    required this.seatInfo,
    required this.status,
  });

  factory CheckInTicket.fromJson(Map<String, dynamic> json) {
    return CheckInTicket(
      reservationNo: json['ReservationNo'] as String? ?? '',
      passengerName: json['PassengerName'] as String? ?? '',
      passportNo: json['PassportNo'] as String? ?? 'Pasaport girilmedi',
      route: json['Route'] as String? ?? '',
      reservationDate: json['ReservationDate'] as String? ?? '',
      seatInfo: json['SeatInfo'] as String? ?? '',
      status: json['Status'] as String? ?? 'Bekleyen',
    );
  }

  /// Status kontrolü için helper
  bool get isCompleted => status == 'Tamamlanan';
  bool get isPending => status == 'Bekleyen';
}

/// Check-in yolcu detay modeli
class CheckInPassenger {
  final String reservationNo;
  final String fullName;
  final int? age;
  final String gender;
  final String passportNo;
  final String nationality;
  final String email;
  final String phone;
  final String flightNo;
  final String route;
  final String seatNumber;
  final String status;

  CheckInPassenger({
    required this.reservationNo,
    required this.fullName,
    this.age,
    required this.gender,
    required this.passportNo,
    required this.nationality,
    required this.email,
    required this.phone,
    required this.flightNo,
    required this.route,
    required this.seatNumber,
    required this.status,
  });

  factory CheckInPassenger.fromJson(Map<String, dynamic> json) {
    return CheckInPassenger(
      reservationNo: json['reservationNo'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      age: json['age'] as int?,
      gender: json['gender'] as String? ?? '',
      passportNo: json['passportNo'] as String? ?? '',
      nationality: json['nationality'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      flightNo: json['flightNo'] as String? ?? '',
      route: json['route'] as String? ?? '',
      seatNumber: json['seatNumber'] as String? ?? '',
      status: json['status'] as String? ?? '',
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
  static const String _ticketListApiUrl =
      'http://localhost:3000/api/checkin/ticket-list';
  static const String _passengerDetailListApiUrl =
      'http://localhost:3000/api/checkin/passenger-detail-list';
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

  /// Check-in yapılacak bilet listesini getirir
  /// Başarılıysa CheckInTicket listesi, başarısızsa boş liste döner
  Future<List<CheckInTicket>> getTicketList() async {
    try {
      final response = await http.get(
        Uri.parse(_ticketListApiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // API'den gelen data'yı CheckInTicket listesine dönüştür
        final data = responseBody['data'] as List<dynamic>?;
        debugPrint('📥 Ticket list API raw data: $data');
        if (data != null) {
          return data
              .map((item) => CheckInTicket.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }

      // Hata durumunda boş liste döndür
      debugPrint('⚠️ Ticket list API hatası: ${response.statusCode}');
      return [];
    } catch (e) {
      // Ağ bağlantısı hatası
      debugPrint('❌ Ticket list HTTP hatası: $e');
      // Hata durumunda boş liste döndür
      return [];
    }
  }

  /// Yolcu detay listesini getirir
  /// Başarılıysa CheckInPassenger listesi, başarısızsa boş liste döner
  Future<List<CheckInPassenger>> getPassengerDetailList() async {
    try {
      final response = await http.get(
        Uri.parse(_passengerDetailListApiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Passenger detail list API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        debugPrint('Response body (ilk 200 karakter): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        return [];
      }

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // API'den gelen data'yı CheckInPassenger listesine dönüştür
        final data = responseBody['data'] as List<dynamic>?;
        debugPrint('📥 Passenger detail list API raw data: $data');
        if (data != null) {
          return data
              .map((item) => CheckInPassenger.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }

      // Hata durumunda boş liste döndür
      debugPrint('⚠️ Passenger detail list API hatası: ${response.statusCode}');
      debugPrint('Response: ${response.body}');
      return [];
    } catch (e) {
      // Ağ bağlantısı hatası veya JSON parse hatası
      debugPrint('❌ Passenger detail list HTTP hatası: $e');
      // Hata durumunda boş liste döndür
      return [];
    }
  }
}
