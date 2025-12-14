import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Otopark ödeme istatistikleri modeli
class ParkingPaymentStatistics {
  final double totalRevenue;
  final int totalTransactionCount;
  final double averagePayment;

  ParkingPaymentStatistics({
    required this.totalRevenue,
    required this.totalTransactionCount,
    required this.averagePayment,
  });

  factory ParkingPaymentStatistics.fromJson(Map<String, dynamic> json) {
    return ParkingPaymentStatistics(
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalTransactionCount: json['totalTransactionCount'] as int? ?? 0,
      averagePayment: (json['averagePayment'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Varsayılan (boş) istatistik oluştur
  factory ParkingPaymentStatistics.empty() {
    return ParkingPaymentStatistics(
      totalRevenue: 0.0,
      totalTransactionCount: 0,
      averagePayment: 0.0,
    );
  }
}

/// Otopark ödeme detay modeli
class ParkingPayment {
  final String paymentId;
  final String plateNumber;
  final String vehicleType;
  final String ownerName;
  final String spotNumber;
  final String checkInTime; // HH:mm formatında
  final String checkOutTime; // HH:mm formatında
  final int stayDurationMinutes;
  final String paymentMethod;
  final String status;
  final double amount;

  ParkingPayment({
    required this.paymentId,
    required this.plateNumber,
    required this.vehicleType,
    required this.ownerName,
    required this.spotNumber,
    required this.checkInTime,
    required this.checkOutTime,
    required this.stayDurationMinutes,
    required this.paymentMethod,
    required this.status,
    required this.amount,
  });

  factory ParkingPayment.fromJson(Map<String, dynamic> json) {
    return ParkingPayment(
      paymentId: json['paymentId'] as String? ?? '',
      plateNumber: json['plateNumber'] as String? ?? '',
      vehicleType: json['vehicleType'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? '',
      spotNumber: json['spotNumber'] as String? ?? '',
      checkInTime: json['checkInTime'] as String? ?? '',
      checkOutTime: json['checkOutTime'] as String? ?? '',
      stayDurationMinutes: json['stayDurationMinutes'] as int? ?? 0,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      status: json['status'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Otopark rezervasyon detay modeli
class ParkingReservation {
  final String reservationNo;
  final String plateNumber;
  final String customerName;
  final String phone;
  final String parkingSpot;
  final String startTime; // ISO formatında
  final String endTime; // ISO formatında
  final double amount;
  final String status;
  final String paymentMethod;

  ParkingReservation({
    required this.reservationNo,
    required this.plateNumber,
    required this.customerName,
    required this.phone,
    required this.parkingSpot,
    required this.startTime,
    required this.endTime,
    required this.amount,
    required this.status,
    required this.paymentMethod,
  });

  factory ParkingReservation.fromJson(Map<String, dynamic> json) {
    return ParkingReservation(
      reservationNo: json['reservationNo'] as String? ?? '',
      plateNumber: json['plateNumber'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      parkingSpot: json['parkingSpot'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? '',
    );
  }
}

class ParkingService {
  // Singleton yapısı
  static final ParkingService _instance = ParkingService._internal();
  factory ParkingService() => _instance;
  ParkingService._internal();

  // ⚠️ API Adresi: Chrome/Web uygulaması için localhost kullanılmalıdır.
  static const String _paymentStatisticsApiUrl =
      'http://localhost:3000/api/parking/payment-statistics';
  static const String _paymentListApiUrl =
      'http://localhost:3000/api/parking/payment-list';
  static const String _reservationListApiUrl =
      'http://localhost:3000/api/parking/reservation-list';
  static const String _updateReservationApiUrl =
      'http://localhost:3000/api/parking/update-reservation';
  // Mobil (Android Emülatörü) için: 'http://10.0.2.2:3000/api/parking/...'
  // Mobil (Gerçek Cihaz) için: Bilgisayarınızın yerel IP adresi.

  /// Otopark ödeme istatistiklerini getirir
  /// Başarılıysa ParkingPaymentStatistics, başarısızsa null döner
  Future<ParkingPaymentStatistics?> getPaymentStatistics() async {
    try {
      debugPrint('📡 Calling payment statistics API: $_paymentStatisticsApiUrl');
      final response = await http.get(
        Uri.parse(_paymentStatisticsApiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('📡 Payment statistics API response: status=${response.statusCode}, body length=${response.body.length}');

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Parking payment statistics API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        debugPrint('⚠️ Response body (first 200 chars): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        return ParkingPaymentStatistics.empty();
      }

      final responseBody = json.decode(response.body);
      debugPrint('📥 Payment statistics API response body: $responseBody');

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // API'den gelen data'yı ParkingPaymentStatistics modeline dönüştür
        final data = responseBody['data'] as Map<String, dynamic>?;
        debugPrint('📥 Parking payment statistics API raw data: $data');
        if (data != null) {
          final stats = ParkingPaymentStatistics.fromJson(data);
          debugPrint('✅ Parsed statistics: totalRevenue=${stats.totalRevenue}, totalCount=${stats.totalTransactionCount}, average=${stats.averagePayment}');
          return stats;
        }
        debugPrint('⚠️ Payment statistics data is null');
      } else {
        debugPrint('⚠️ Payment statistics API response not successful: status=${response.statusCode}, success=${responseBody['success']}');
      }

      // Hata durumunda varsayılan değerler döndür
      debugPrint('⚠️ Parking payment statistics API hatası: ${response.statusCode}');
      return ParkingPaymentStatistics.empty();
    } catch (e) {
      // Ağ bağlantısı hatası
      debugPrint('❌ Parking payment statistics HTTP hatası: $e');
      // Hata durumunda varsayılan değerler döndür
      return ParkingPaymentStatistics.empty();
    }
  }

  /// Otopark ödeme detay listesini getirir
  /// Başarılıysa List<ParkingPayment>, başarısızsa boş liste döner
  Future<List<ParkingPayment>> getPaymentList() async {
    try {
      final response = await http.get(
        Uri.parse(_paymentListApiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Parking payment list API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        return [];
      }

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // API'den gelen data listesini ParkingPayment modeline dönüştür
        final data = responseBody['data'] as List<dynamic>?;
        debugPrint('📥 Parking payment list API: ${data?.length ?? 0} payments retrieved');
        if (data != null && data.isNotEmpty) {
          debugPrint('📋 First payment sample: ${data[0]}');
          final payments = data.map((item) => ParkingPayment.fromJson(item as Map<String, dynamic>)).toList();
          debugPrint('✅ Parsed ${payments.length} payments successfully');
          return payments;
        }
        debugPrint('⚠️ API returned empty data array');
        return [];
      }
      
      debugPrint('⚠️ API response not successful: status=${response.statusCode}, success=${responseBody['success']}');

      // Hata durumunda boş liste döndür
      debugPrint('⚠️ Parking payment list API hatası: ${response.statusCode}');
      return [];
    } catch (e) {
      // Ağ bağlantısı hatası
      debugPrint('❌ Parking payment list HTTP hatası: $e');
      return [];
    }
  }

  /// Otopark rezervasyon detay listesini getirir
  /// Başarılıysa List<ParkingReservation>, başarısızsa boş liste döner
  Future<List<ParkingReservation>> getReservationList() async {
    try {
      debugPrint('📡 Calling reservation list API: $_reservationListApiUrl');
      final response = await http.get(
        Uri.parse(_reservationListApiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Parking reservation list API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        return [];
      }

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // API'den gelen data listesini ParkingReservation modeline dönüştür
        final data = responseBody['data'] as List<dynamic>?;
        debugPrint('📥 Parking reservation list API: ${data?.length ?? 0} reservations retrieved');
        if (data != null && data.isNotEmpty) {
          debugPrint('📋 First reservation sample: ${data[0]}');
          final reservations = data.map((item) => ParkingReservation.fromJson(item as Map<String, dynamic>)).toList();
          debugPrint('✅ Parsed ${reservations.length} reservations successfully');
          return reservations;
        }
        debugPrint('⚠️ API returned empty data array');
        return [];
      }
      
      debugPrint('⚠️ API response not successful: status=${response.statusCode}, success=${responseBody['success']}');

      // Hata durumunda boş liste döndür
      debugPrint('⚠️ Parking reservation list API hatası: ${response.statusCode}');
      return [];
    } catch (e) {
      // Ağ bağlantısı hatası
      debugPrint('❌ Parking reservation list HTTP hatası: $e');
      return [];
    }
  }

  /// Otopark rezervasyon bilgilerini günceller
  /// Başarılıysa true, başarısızsa false döner
  Future<bool> updateReservation({
    required String reservationCode,
    required String plateNumber,
    required String fullName,
    required String phone,
    required String status,
    required int actionUserId,
  }) async {
    try {
      debugPrint('📡 Calling update reservation API: $_updateReservationApiUrl');
      debugPrint('📋 Update data: reservationCode=$reservationCode, plateNumber=$plateNumber, fullName=$fullName, phone=$phone, status=$status, actionUserId=$actionUserId');
      
      final response = await http.put(
        Uri.parse(_updateReservationApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'reservationCode': reservationCode,
          'plateNumber': plateNumber,
          'fullName': fullName,
          'phone': phone,
          'status': status,
          'actionUserId': actionUserId,
        }),
      );

      debugPrint('📡 Update reservation API response: status=${response.statusCode}');

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Parking update reservation API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        return false;
      }

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        debugPrint('✅ Reservation updated successfully');
        return true;
      } else {
        debugPrint('⚠️ Update reservation API response not successful: status=${response.statusCode}, message=${responseBody['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Parking update reservation HTTP hatası: $e');
      return false;
    }
  }
}




