import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Admin dashboard istatistikleri modeli
class AdminDashboardStats {
  final int todayFlights;
  final int activeReservations;
  final int occupiedParkingSpots;
  final double totalRevenue;

  AdminDashboardStats({
    required this.todayFlights,
    required this.activeReservations,
    required this.occupiedParkingSpots,
    required this.totalRevenue,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStats(
      todayFlights: json['todayFlights'] as int? ?? 0,
      activeReservations: json['activeReservations'] as int? ?? 0,
      occupiedParkingSpots: json['occupiedParkingSpots'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Varsayılan (boş) istatistik oluştur
  factory AdminDashboardStats.empty() {
    return AdminDashboardStats(
      todayFlights: 0,
      activeReservations: 0,
      occupiedParkingSpots: 0,
      totalRevenue: 0.0,
    );
  }
}

class AdminService {
  // Singleton yapısı
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  // ⚠️ API Adresi: Chrome/Web uygulaması için localhost kullanılmalıdır.
  static const String _dashboardStatsApiUrl =
      'http://localhost:3000/api/admin/dashboard-stats';
  static const String _todayFlightsApiUrl =
      'http://localhost:3000/api/admin/today-flights';
  static const String _gatesApiUrl =
      'http://localhost:3000/api/admin/gates';
  static const String _updateGateApiUrl =
      'http://localhost:3000/api/admin/update-gate';
  static const String _deleteGateApiUrl =
      'http://localhost:3000/api/admin/delete-gate';
  static const String _departmentsApiUrl =
      'http://localhost:3000/api/admin/departments';
  static const String _addDepartmentApiUrl =
      'http://localhost:3000/api/admin/add-department';
  static const String _updateDepartmentApiUrl =
      'http://localhost:3000/api/admin/update-department';
  static const String _deleteDepartmentApiUrl =
      'http://localhost:3000/api/admin/delete-department';
  static const String _employeesApiUrl =
      'http://localhost:3000/api/admin/employees';
  static const String _addEmployeeApiUrl =
      'http://localhost:3000/api/admin/add-employee';
  static const String _updateEmployeeApiUrl =
      'http://localhost:3000/api/admin/update-employee';
  static const String _deleteEmployeeApiUrl =
      'http://localhost:3000/api/admin/delete-employee';
  static const String _activityLogsApiUrl =
      'http://localhost:3000/api/admin/activity-logs';
  static const String _reservationsApiUrl =
      'http://localhost:3000/api/admin/reservations';
  static const String _addReservationApiUrl =
      'http://localhost:3000/api/admin/add-reservation';
  static const String _deleteReservationApiUrl =
      'http://localhost:3000/api/admin/delete-reservation';
  static const String _passengersApiUrl =
      'http://localhost:3000/api/admin/passengers';
  static const String _updatePassengerApiUrl =
      'http://localhost:3000/api/admin/update-passenger';
  static const String _deletePassengerApiUrl =
      'http://localhost:3000/api/admin/delete-passenger';
  static const String _addPassengerApiUrl =
      'http://localhost:3000/api/admin/add-passenger';
  static const String _vehicleTypesApiUrl =
      'http://localhost:3000/api/admin/vehicle-types';
  // Mobil (Android Emülatörü) için: 'http://10.0.2.2:3000/api/admin/...'
  // Mobil (Gerçek Cihaz) için: Bilgisayarınızın yerel IP adresi.

  /// Admin dashboard istatistiklerini getirir
  /// Başarılıysa AdminDashboardStats, başarısızsa empty stats döner
  Future<AdminDashboardStats> getDashboardStats() async {
    try {
      debugPrint('📡 Calling admin dashboard stats API: $_dashboardStatsApiUrl');
      final response = await http.get(
        Uri.parse(_dashboardStatsApiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('📡 Admin dashboard stats API response: status=${response.statusCode}, body length=${response.body.length}');

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin dashboard stats API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        debugPrint('⚠️ Response body (first 200 chars): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        return AdminDashboardStats.empty();
      }

      final responseBody = json.decode(response.body);
      debugPrint('📥 Admin dashboard stats API response body: $responseBody');

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // API'den gelen data'yı AdminDashboardStats modeline dönüştür
        final data = responseBody['data'] as Map<String, dynamic>?;
        debugPrint('📥 Admin dashboard stats API raw data: $data');
        if (data != null) {
          final stats = AdminDashboardStats.fromJson(data);
          debugPrint('✅ Parsed stats: todayFlights=${stats.todayFlights}, activeReservations=${stats.activeReservations}, occupiedParkingSpots=${stats.occupiedParkingSpots}, totalRevenue=${stats.totalRevenue}');
          return stats;
        }
        debugPrint('⚠️ Dashboard stats data is null');
      } else {
        debugPrint('⚠️ Dashboard stats API response not successful: status=${response.statusCode}, success=${responseBody['success']}');
      }

      // Hata durumunda varsayılan değerler döndür
      debugPrint('⚠️ Admin dashboard stats API hatası: ${response.statusCode}');
      return AdminDashboardStats.empty();
    } catch (e) {
      // Ağ bağlantısı hatası
      debugPrint('❌ Admin dashboard stats HTTP hatası: $e');
      // Hata durumunda varsayılan değerler döndür
      return AdminDashboardStats.empty();
    }
  }

  /// Bugünkü son 5 uçuşu getirir
  /// Başarılıysa List<TodayFlight>, başarısızsa boş liste döner
  Future<List<TodayFlight>> getTodayFlights() async {
    try {
      debugPrint('📡 Calling today flights API: $_todayFlightsApiUrl');
      final response = await http.get(
        Uri.parse(_todayFlightsApiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin today flights API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        return [];
      }

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // API'den gelen data listesini TodayFlight modeline dönüştür
        final data = responseBody['data'] as List<dynamic>?;
        debugPrint('📥 Admin today flights API: ${data?.length ?? 0} flights retrieved');
        if (data != null && data.isNotEmpty) {
          debugPrint('📋 First flight sample: ${data[0]}');
          final flights = data.map((item) => TodayFlight.fromJson(item as Map<String, dynamic>)).toList();
          debugPrint('✅ Parsed ${flights.length} flights successfully');
          return flights;
        }
        debugPrint('⚠️ API returned empty data array');
        return [];
      }
      
      debugPrint('⚠️ API response not successful: status=${response.statusCode}, success=${responseBody['success']}');

      // Hata durumunda boş liste döndür
      debugPrint('⚠️ Admin today flights API hatası: ${response.statusCode}');
      return [];
    } catch (e) {
      // Ağ bağlantısı hatası
      debugPrint('❌ Admin today flights HTTP hatası: $e');
      return [];
    }
  }

  /// Tüm kapıları getirir
  /// Başarılıysa List<Gate>, başarısızsa boş liste döner
  Future<List<Gate>> getGates() async {
    try {
      debugPrint('📡 Calling gates API: $_gatesApiUrl');
      final response = await http.get(
        Uri.parse(_gatesApiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin gates API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        return [];
      }

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // API'den gelen data listesini Gate modeline dönüştür
        final data = responseBody['data'] as List<dynamic>?;
        debugPrint('📥 Admin gates API: ${data?.length ?? 0} gates retrieved');
        if (data != null && data.isNotEmpty) {
          debugPrint('📋 First gate sample: ${data[0]}');
          final gates = data.map((item) => Gate.fromJson(item as Map<String, dynamic>)).toList();
          debugPrint('✅ Parsed ${gates.length} gates successfully');
          return gates;
        }
        debugPrint('⚠️ API returned empty data array');
        return [];
      }
      
      debugPrint('⚠️ API response not successful: status=${response.statusCode}, success=${responseBody['success']}');

      // Hata durumunda boş liste döndür
      debugPrint('⚠️ Admin gates API hatası: ${response.statusCode}');
      return [];
    } catch (e) {
      // Ağ bağlantısı hatası
      debugPrint('❌ Admin gates HTTP hatası: $e');
      return [];
    }
  }

  /// Kapı bilgilerini günceller
  /// Başarılıysa true, başarısızsa false döner
  Future<bool> updateGate({
    required int gateId,
    required String gateCode,
    required String terminal,
    required String status,
    required int userId,
  }) async {
    try {
      debugPrint('📡 Calling update gate API: $_updateGateApiUrl');
      debugPrint('📋 Update data: gateId=$gateId, gateCode=$gateCode, terminal=$terminal, status=$status, userId=$userId');
      
      final response = await http.put(
        Uri.parse(_updateGateApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'gateId': gateId,
          'gateCode': gateCode,
          'terminal': terminal,
          'status': status,
          'userId': userId,
        }),
      );

      debugPrint('📡 Update gate API response: status=${response.statusCode}');

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin update gate API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        return false;
      }

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        debugPrint('✅ Gate updated successfully');
        return true;
      } else {
        debugPrint('⚠️ Update gate API response not successful: status=${response.statusCode}, message=${responseBody['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Admin update gate HTTP hatası: $e');
      return false;
    }
  }

  /// Kapıyı siler
  /// Başarılıysa true, başarısızsa false döner
  Future<bool> deleteGate({
    required int gateId,
    required int userId,
  }) async {
    try {
      debugPrint('📡 Calling delete gate API: $_deleteGateApiUrl');
      debugPrint('📋 Delete data: gateId=$gateId, userId=$userId');
      
      final response = await http.delete(
        Uri.parse(_deleteGateApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'gateId': gateId,
          'userId': userId,
        }),
      );

      debugPrint('📡 Delete gate API response: status=${response.statusCode}');

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin delete gate API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        return false;
      }

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        debugPrint('✅ Gate deleted successfully');
        return true;
      } else {
        debugPrint('⚠️ Delete gate API response not successful: status=${response.statusCode}, message=${responseBody['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Admin delete gate HTTP hatası: $e');
      return false;
    }
  }

  /// Tüm çalışanları getirir
  /// Başarılıysa List<Employee>, başarısızsa boş liste döner
  Future<List<Employee>> getEmployees() async {
    try {
      debugPrint('📡 Calling employees API: $_employeesApiUrl');
      final response = await http.get(
        Uri.parse(_employeesApiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin employees API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        return [];
      }

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // API'den gelen data listesini Employee modeline dönüştür
        final data = responseBody['data'] as List<dynamic>?;
        debugPrint('📥 Admin employees API: ${data?.length ?? 0} employees retrieved');
        if (data != null && data.isNotEmpty) {
          debugPrint('📋 First employee sample: ${data[0]}');
          final employees = data.map((item) => Employee.fromJson(item as Map<String, dynamic>)).toList();
          debugPrint('✅ Parsed ${employees.length} employees successfully');
          return employees;
        }
        debugPrint('⚠️ API returned empty data array');
        return [];
      }
      
      debugPrint('⚠️ API response not successful: status=${response.statusCode}, success=${responseBody['success']}');

      // Hata durumunda boş liste döndür
      debugPrint('⚠️ Admin employees API hatası: ${response.statusCode}');
      return [];
    } catch (e) {
      // Ağ bağlantısı hatası
      debugPrint('❌ Admin employees HTTP hatası: $e');
      return [];
    }
  }

  /// Çalışan bilgilerini günceller
  /// Başarılıysa true, başarısızsa false döner
  Future<bool> updateEmployee({
    required int employeeId,
    required String firstName,
    required String lastName,
    required int departmentId,
    required double salary,
    required String contact,
    required String role,
    required int userId,
  }) async {
    try {
      debugPrint('📡 Calling update employee API: $_updateEmployeeApiUrl');
      debugPrint('📋 Update data: employeeId=$employeeId, firstName=$firstName, lastName=$lastName, departmentId=$departmentId, salary=$salary, contact=$contact, role=$role, userId=$userId');
      
      final response = await http.put(
        Uri.parse(_updateEmployeeApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'employeeId': employeeId,
          'firstName': firstName,
          'lastName': lastName,
          'departmentId': departmentId,
          'salary': salary,
          'contact': contact,
          'role': role,
          'userId': userId,
        }),
      );

      debugPrint('📡 Update employee API response: status=${response.statusCode}');
      debugPrint('📡 Update employee API response body (raw): ${response.body}');

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin update employee API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        debugPrint('⚠️ Response body (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
        return false;
      }

      final responseBody = json.decode(response.body);
      debugPrint('📥 Update employee API response body (parsed): $responseBody');

      if (response.statusCode == 200 && responseBody['success'] == true) {
        debugPrint('✅ Employee updated successfully');
        return true;
      } else {
        final errorMessage = responseBody['message'] ?? 'Bilinmeyen hata';
        debugPrint('⚠️ Update employee API response not successful: status=${response.statusCode}, message=$errorMessage');
        debugPrint('⚠️ Full response body: $responseBody');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Admin update employee HTTP hatası: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      if (e is Exception) {
        debugPrint('❌ Exception details: $e');
      }
      return false;
    }
  }

  /// Yeni çalışan ekler
  /// Başarılıysa true, başarısızsa false döner
  Future<bool> addEmployee({
    required String firstName,
    required String lastName,
    required int departmentId,
    required double salary,
    required String contact,
    required String role,
    required int userId,
  }) async {
    try {
      debugPrint('📡 Calling add employee API: $_addEmployeeApiUrl');
      debugPrint('📋 Add data: firstName=$firstName, lastName=$lastName, departmentId=$departmentId, salary=$salary, contact=$contact, role=$role, userId=$userId');
      
      final response = await http.post(
        Uri.parse(_addEmployeeApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'firstName': firstName,
          'lastName': lastName,
          'departmentId': departmentId,
          'salary': salary,
          'contact': contact,
          'role': role,
          'userId': userId,
        }),
      );

      debugPrint('📡 Add employee API response: status=${response.statusCode}');
      debugPrint('📡 Add employee API response body (raw): ${response.body}');

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin add employee API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        debugPrint('⚠️ Response body (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
        return false;
      }

      final responseBody = json.decode(response.body);
      debugPrint('📥 Add employee API response body (parsed): $responseBody');

      if (response.statusCode == 200 && responseBody['success'] == true) {
        debugPrint('✅ Employee added successfully');
        return true;
      } else {
        final errorMessage = responseBody['message'] ?? 'Bilinmeyen hata';
        debugPrint('⚠️ Add employee API response not successful: status=${response.statusCode}, message=$errorMessage');
        debugPrint('⚠️ Full response body: $responseBody');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Admin add employee HTTP hatası: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      if (e is Exception) {
        debugPrint('❌ Exception details: $e');
      }
      return false;
    }
  }

  /// Çalışanı siler
  /// Başarılıysa true, başarısızsa false döner
  Future<bool> deleteEmployee({
    required int employeeId,
    required int userId,
  }) async {
    try {
      debugPrint('📡 Calling delete employee API: $_deleteEmployeeApiUrl');
      debugPrint('📋 Delete data: employeeId=$employeeId, userId=$userId');
      
      final response = await http.delete(
        Uri.parse(_deleteEmployeeApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'employeeId': employeeId,
          'userId': userId,
        }),
      );

      debugPrint('📡 Delete employee API response: status=${response.statusCode}');
      debugPrint('📡 Delete employee API response body (raw): ${response.body}');

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin delete employee API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        debugPrint('⚠️ Response body (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
        return false;
      }

      final responseBody = json.decode(response.body);
      debugPrint('📥 Delete employee API response body (parsed): $responseBody');

      if (response.statusCode == 200 && responseBody['success'] == true) {
        debugPrint('✅ Employee deleted successfully');
        return true;
      } else {
        final errorMessage = responseBody['message'] ?? 'Bilinmeyen hata';
        debugPrint('⚠️ Delete employee API response not successful: status=${response.statusCode}, message=$errorMessage');
        debugPrint('⚠️ Full response body: $responseBody');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Admin delete employee HTTP hatası: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      if (e is Exception) {
        debugPrint('❌ Exception details: $e');
      }
      return false;
    }
  }

  /// Tüm departmanları getirir
  /// Başarılıysa List<Department>, başarısızsa boş liste döner
  Future<List<Department>> getDepartments() async {
    try {
      debugPrint('📡 Calling departments API: $_departmentsApiUrl');
      final response = await http.get(
        Uri.parse(_departmentsApiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin departments API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        return [];
      }

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // API'den gelen data listesini Department modeline dönüştür
        final data = responseBody['data'] as List<dynamic>?;
        debugPrint('📥 Admin departments API: ${data?.length ?? 0} departments retrieved');
        if (data != null && data.isNotEmpty) {
          debugPrint('📋 First department sample: ${data[0]}');
          final departments = data.map((item) => Department.fromJson(item as Map<String, dynamic>)).toList();
          debugPrint('✅ Parsed ${departments.length} departments successfully');
          return departments;
        }
        debugPrint('⚠️ API returned empty data array');
        return [];
      }
      
      debugPrint('⚠️ API response not successful: status=${response.statusCode}, success=${responseBody['success']}');

      // Hata durumunda boş liste döndür
      debugPrint('⚠️ Admin departments API hatası: ${response.statusCode}');
      return [];
    } catch (e) {
      // Ağ bağlantısı hatası
      debugPrint('❌ Admin departments HTTP hatası: $e');
      return [];
    }
  }

  /// Tüm aktivite loglarını getirir
  /// Başarılıysa List<ActivityLog>, başarısızsa boş liste döner
  Future<List<ActivityLog>> getActivityLogs() async {
    try {
      debugPrint('📡 Calling activity logs API: $_activityLogsApiUrl');
      final response = await http.get(
        Uri.parse(_activityLogsApiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin activity logs API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        return [];
      }

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // API'den gelen data listesini ActivityLog modeline dönüştür
        final data = responseBody['data'] as List<dynamic>?;
        debugPrint('📥 Admin activity logs API: ${data?.length ?? 0} logs retrieved');
        if (data != null && data.isNotEmpty) {
          debugPrint('📋 First log sample: ${data[0]}');
          final logs = data.map((item) => ActivityLog.fromJson(item as Map<String, dynamic>)).toList();
          debugPrint('✅ Parsed ${logs.length} activity logs successfully');
          return logs;
        }
        debugPrint('⚠️ API returned empty data array');
        return [];
      }
      
      debugPrint('⚠️ API response not successful: status=${response.statusCode}, success=${responseBody['success']}');

      // Hata durumunda boş liste döndür
      debugPrint('⚠️ Admin activity logs API hatası: ${response.statusCode}');
      return [];
    } catch (e) {
      // Ağ bağlantısı hatası
      debugPrint('❌ Admin activity logs HTTP hatası: $e');
      return [];
    }
  }

  /// Tüm rezervasyonları getirir
  /// Başarılıysa List<Reservation>, başarısızsa boş liste döner
  Future<List<Reservation>> getReservations() async {
    try {
      debugPrint('📡 Calling reservations API: $_reservationsApiUrl');
      final response = await http.get(
        Uri.parse(_reservationsApiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin reservations API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        return [];
      }

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // API'den gelen data listesini Reservation modeline dönüştür
        final data = responseBody['data'] as List<dynamic>?;
        debugPrint('📥 Admin reservations API: ${data?.length ?? 0} reservations retrieved');
        if (data != null && data.isNotEmpty) {
          debugPrint('📋 First reservation sample: ${data[0]}');
          final reservations = data.map((item) => Reservation.fromJson(item as Map<String, dynamic>)).toList();
          debugPrint('✅ Parsed ${reservations.length} reservations successfully');
          return reservations;
        }
        debugPrint('⚠️ API returned empty data array');
        return [];
      }
      
      debugPrint('⚠️ API response not successful: status=${response.statusCode}, success=${responseBody['success']}');

      // Hata durumunda boş liste döndür
      debugPrint('⚠️ Admin reservations API hatası: ${response.statusCode}');
      return [];
    } catch (e) {
      // Ağ bağlantısı hatası
      debugPrint('❌ Admin reservations HTTP hatası: $e');
      return [];
    }
  }

  /// Tüm yolcuları getirir
  /// Başarılıysa List<Passenger>, başarısızsa boş liste döner
  Future<List<Passenger>> getPassengers() async {
    try {
      debugPrint('📡 Calling passengers API: $_passengersApiUrl');
      final response = await http.get(
        Uri.parse(_passengersApiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin passengers API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        return [];
      }

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // API'den gelen data listesini Passenger modeline dönüştür
        final data = responseBody['data'] as List<dynamic>?;
        debugPrint('📥 Admin passengers API: ${data?.length ?? 0} passengers retrieved');
        if (data != null && data.isNotEmpty) {
          debugPrint('📋 First passenger sample: ${data[0]}');
          final passengers = data.map((item) => Passenger.fromJson(item as Map<String, dynamic>)).toList();
          debugPrint('✅ Parsed ${passengers.length} passengers successfully');
          return passengers;
        }
        debugPrint('⚠️ API returned empty data array');
        return [];
      }
      
      debugPrint('⚠️ API response not successful: status=${response.statusCode}, success=${responseBody['success']}');

      // Hata durumunda boş liste döndür
      debugPrint('⚠️ Admin passengers API hatası: ${response.statusCode}');
      return [];
    } catch (e) {
      // Ağ bağlantısı hatası
      debugPrint('❌ Admin passengers HTTP hatası: $e');
      return [];
    }
  }

  /// Yolcu bilgilerini günceller
  /// Başarılıysa true, başarısızsa false döner
  Future<bool> updatePassenger({
    required int passengerId,
    required String firstName,
    required String lastName,
    required String passportNo,
    int? age,
    String? gender,
    String? nationality,
    required int userId,
  }) async {
    try {
      debugPrint('📡 Calling update passenger API: $_updatePassengerApiUrl');
      
      final requestBody = {
        'passengerId': passengerId,
        'firstName': firstName,
        'lastName': lastName,
        'passportNo': passportNo,
        'age': age,
        'gender': gender,
        'nationality': nationality,
        'userId': userId,
      };

      debugPrint('📋 Update passenger request body: $requestBody');

      final response = await http.put(
        Uri.parse(_updatePassengerApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      debugPrint('📡 Update passenger API response: status=${response.statusCode}, body length=${response.body.length}');

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        debugPrint('✅ Passenger updated successfully');
        return true;
      }

      debugPrint('⚠️ Update passenger API response not successful: status=${response.statusCode}, success=${responseBody['success']}');
      debugPrint('⚠️ Error message: ${responseBody['message'] ?? 'Bilinmeyen hata'}');
      return false;
    } catch (e) {
      debugPrint('❌ Update passenger HTTP hatası: $e');
      return false;
    }
  }

  /// Yeni yolcu ekler
  /// Başarılıysa PassengerID döner, başarısızsa null döner
  Future<int?> addPassenger({
    required int reservationId,
    required String firstName,
    required String lastName,
    required String passportNo,
    int? age,
    String? gender,
    String? nationality,
    required int userId,
  }) async {
    try {
      debugPrint('📡 Calling add passenger API: $_addPassengerApiUrl');
      
      final requestBody = {
        'reservationId': reservationId,
        'firstName': firstName,
        'lastName': lastName,
        'passportNo': passportNo,
        'age': age,
        'gender': gender,
        'nationality': nationality,
        'userId': userId,
      };

      debugPrint('📋 Add passenger request body: $requestBody');

      final response = await http.post(
        Uri.parse(_addPassengerApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      debugPrint('📡 Add passenger API response: status=${response.statusCode}, body length=${response.body.length}');

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final passengerId = responseBody['data']?['passengerId'] as int?;
        debugPrint('✅ Passenger added successfully with ID: $passengerId');
        return passengerId;
      }

      debugPrint('⚠️ Add passenger API response not successful: status=${response.statusCode}, success=${responseBody['success']}');
      debugPrint('⚠️ Error message: ${responseBody['message'] ?? 'Bilinmeyen hata'}');
      return null;
    } catch (e) {
      debugPrint('❌ Add passenger HTTP hatası: $e');
      return null;
    }
  }

  /// Tüm araç tiplerini getirir
  /// Başarılıysa List<VehicleType>, başarısızsa boş liste döner
  Future<List<VehicleType>> getVehicleTypes() async {
    try {
      debugPrint('📡 Calling vehicle types API: $_vehicleTypesApiUrl');
      final response = await http.get(
        Uri.parse(_vehicleTypesApiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin vehicle types API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        return [];
      }

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // API'den gelen data listesini VehicleType modeline dönüştür
        final data = responseBody['data'] as List<dynamic>?;
        debugPrint('📥 Admin vehicle types API: ${data?.length ?? 0} vehicle types retrieved');
        if (data != null && data.isNotEmpty) {
          debugPrint('📋 First vehicle type sample: ${data[0]}');
          final vehicleTypes = data.map((item) => VehicleType.fromJson(item as Map<String, dynamic>)).toList();
          debugPrint('✅ Parsed ${vehicleTypes.length} vehicle types successfully');
          return vehicleTypes;
        }
        debugPrint('⚠️ API returned empty data array');
        return [];
      }

      debugPrint('⚠️ API response not successful: status=${response.statusCode}, success=${responseBody['success']}');

      // Hata durumunda boş liste döndür
      debugPrint('⚠️ Admin vehicle types API hatası: ${response.statusCode}');
      return [];
    } catch (e) {
      // Ağ bağlantısı hatası
      debugPrint('❌ Admin vehicle types HTTP hatası: $e');
      return [];
    }
  }

  /// Yolcuyu siler
  /// Başarılıysa true, başarısızsa false döner
  Future<bool> deletePassenger({
    required int passengerId,
    required int userId,
  }) async {
    try {
      debugPrint('📡 Calling delete passenger API: $_deletePassengerApiUrl');
      
      final requestBody = {
        'passengerId': passengerId,
        'userId': userId,
      };

      debugPrint('📋 Delete passenger request body: $requestBody');

      final response = await http.delete(
        Uri.parse(_deletePassengerApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      debugPrint('📡 Delete passenger API response: status=${response.statusCode}, body length=${response.body.length}');

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        debugPrint('✅ Passenger deleted successfully');
        return true;
      }

      debugPrint('⚠️ Delete passenger API response not successful: status=${response.statusCode}, success=${responseBody['success']}');
      debugPrint('⚠️ Error message: ${responseBody['message'] ?? 'Bilinmeyen hata'}');
      return false;
    } catch (e) {
      debugPrint('❌ Delete passenger HTTP hatası: $e');
      return false;
    }
  }

  /// Yeni rezervasyon oluşturur
  /// Başarılıysa ReservationID döner, başarısızsa null döner
  Future<int?> addReservation({
    required int userId,
    required int flightId,
    required DateTime reservationDate,
    String status = 'Pending',
    required double totalAmount,
    required String passengerFirstName,
    required String passengerLastName,
    required String passportNo,
    required int age,
    String? gender,
    String? nationality,
    int? seatId,
    String? boardingGate,
    String ticketStatus = 'Confirmed',
    required int createdByUserId,
  }) async {
    try {
      debugPrint('📡 Calling add reservation API: $_addReservationApiUrl');
      debugPrint('📋 Add data: userId=$userId, flightId=$flightId, passenger=$passengerFirstName $passengerLastName');
      
      final response = await http.post(
        Uri.parse(_addReservationApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'flightId': flightId,
          'reservationDate': reservationDate.toIso8601String(),
          'status': status,
          'totalAmount': totalAmount,
          'passengerFirstName': passengerFirstName,
          'passengerLastName': passengerLastName,
          'passportNo': passportNo,
          'age': age,
          'gender': gender,
          'nationality': nationality,
          'seatId': seatId,
          'boardingGate': boardingGate,
          'ticketStatus': ticketStatus,
          'createdByUserId': createdByUserId,
        }),
      );

      debugPrint('📡 Add reservation API response: status=${response.statusCode}');
      debugPrint('📡 Add reservation API response body (raw): ${response.body}');

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin add reservation API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        debugPrint('⚠️ Response body (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
        return null;
      }

      final responseBody = json.decode(response.body);
      debugPrint('📥 Add reservation API response body (parsed): $responseBody');

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final reservationId = responseBody['data']?['reservationId'] as int?;
        debugPrint('✅ Reservation created successfully with ID: $reservationId');
        return reservationId;
      } else {
        final errorMessage = responseBody['message'] ?? 'Bilinmeyen hata';
        debugPrint('⚠️ Add reservation API response not successful: status=${response.statusCode}, message=$errorMessage');
        debugPrint('⚠️ Full response body: $responseBody');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Admin add reservation HTTP hatası: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      if (e is Exception) {
        debugPrint('❌ Exception details: $e');
      }
      return null;
    }
  }

  /// Rezervasyonu siler
  /// Başarılıysa true, başarısızsa false döner
  Future<bool> deleteReservation({
    required int reservationId,
    required int userId,
  }) async {
    try {
      debugPrint('📡 Calling delete reservation API: $_deleteReservationApiUrl');
      debugPrint('📋 Delete data: reservationId=$reservationId, userId=$userId');
      
      final response = await http.delete(
        Uri.parse(_deleteReservationApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'reservationId': reservationId,
          'userId': userId,
        }),
      );

      debugPrint('📡 Delete reservation API response: status=${response.statusCode}');
      debugPrint('📡 Delete reservation API response body (raw): ${response.body}');

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin delete reservation API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        debugPrint('⚠️ Response body (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
        return false;
      }

      final responseBody = json.decode(response.body);
      debugPrint('📥 Delete reservation API response body (parsed): $responseBody');

      if (response.statusCode == 200 && responseBody['success'] == true) {
        debugPrint('✅ Reservation deleted successfully');
        return true;
      } else {
        final errorMessage = responseBody['message'] ?? 'Bilinmeyen hata';
        debugPrint('⚠️ Delete reservation API response not successful: status=${response.statusCode}, message=$errorMessage');
        debugPrint('⚠️ Full response body: $responseBody');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Admin delete reservation HTTP hatası: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      if (e is Exception) {
        debugPrint('❌ Exception details: $e');
      }
      return false;
    }
  }

  /// Yeni departman ekler
  /// Başarılıysa true, başarısızsa false döner
  Future<bool> addDepartment({
    required String departmentName,
    required String description,
    required int departmentManagerId,
    required int userId,
  }) async {
    try {
      debugPrint('📡 Calling add department API: $_addDepartmentApiUrl');
      debugPrint('📋 Add data: departmentName=$departmentName, description=$description, departmentManagerId=$departmentManagerId, userId=$userId');
      
      final response = await http.post(
        Uri.parse(_addDepartmentApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'departmentName': departmentName,
          'description': description,
          'departmentManagerId': departmentManagerId,
          'userId': userId,
        }),
      );

      debugPrint('📡 Add department API response: status=${response.statusCode}');
      debugPrint('📡 Add department API response body (raw): ${response.body}');

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin add department API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        debugPrint('⚠️ Response body (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
        return false;
      }

      final responseBody = json.decode(response.body);
      debugPrint('📥 Add department API response body (parsed): $responseBody');

      if (response.statusCode == 200 && responseBody['success'] == true) {
        debugPrint('✅ Department added successfully');
        return true;
      } else {
        final errorMessage = responseBody['message'] ?? 'Bilinmeyen hata';
        debugPrint('⚠️ Add department API response not successful: status=${response.statusCode}, message=$errorMessage');
        debugPrint('⚠️ Full response body: $responseBody');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Admin add department HTTP hatası: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      if (e is Exception) {
        debugPrint('❌ Exception details: $e');
      }
      return false;
    }
  }

  /// Departman bilgilerini günceller
  /// Başarılıysa true, başarısızsa false döner
  Future<bool> updateDepartment({
    required int departmentId,
    required String departmentName,
    required String description,
    required int departmentManagerId,
    required int userId,
  }) async {
    try {
      debugPrint('📡 Calling update department API: $_updateDepartmentApiUrl');
      debugPrint('📋 Update data: departmentId=$departmentId, departmentName=$departmentName, description=$description, departmentManagerId=$departmentManagerId, userId=$userId');
      
      final response = await http.put(
        Uri.parse(_updateDepartmentApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'departmentId': departmentId,
          'departmentName': departmentName,
          'description': description,
          'departmentManagerId': departmentManagerId,
          'userId': userId,
        }),
      );

      debugPrint('📡 Update department API response: status=${response.statusCode}');
      debugPrint('📡 Update department API response body (raw): ${response.body}');

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin update department API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        debugPrint('⚠️ Response body (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
        return false;
      }

      final responseBody = json.decode(response.body);
      debugPrint('📥 Update department API response body (parsed): $responseBody');

      if (response.statusCode == 200 && responseBody['success'] == true) {
        debugPrint('✅ Department updated successfully');
        return true;
      } else {
        final errorMessage = responseBody['message'] ?? 'Bilinmeyen hata';
        debugPrint('⚠️ Update department API response not successful: status=${response.statusCode}, message=$errorMessage');
        debugPrint('⚠️ Full response body: $responseBody');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Admin update department HTTP hatası: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      if (e is Exception) {
        debugPrint('❌ Exception details: $e');
      }
      return false;
    }
  }

  /// Departmanı siler
  /// Başarılıysa true, başarısızsa false döner
  Future<bool> deleteDepartment({
    required int departmentId,
    required int userId,
  }) async {
    try {
      debugPrint('📡 Calling delete department API: $_deleteDepartmentApiUrl');
      debugPrint('📋 Delete data: departmentId=$departmentId, userId=$userId');
      
      final response = await http.delete(
        Uri.parse(_deleteDepartmentApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'departmentId': departmentId,
          'userId': userId,
        }),
      );

      debugPrint('📡 Delete department API response: status=${response.statusCode}');
      debugPrint('📡 Delete department API response body (raw): ${response.body}');

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin delete department API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        debugPrint('⚠️ Response body (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
        return false;
      }

      final responseBody = json.decode(response.body);
      debugPrint('📥 Delete department API response body (parsed): $responseBody');

      if (response.statusCode == 200 && responseBody['success'] == true) {
        debugPrint('✅ Department deleted successfully');
        return true;
      } else {
        final errorMessage = responseBody['message'] ?? 'Bilinmeyen hata';
        debugPrint('⚠️ Delete department API response not successful: status=${response.statusCode}, message=$errorMessage');
        debugPrint('⚠️ Full response body: $responseBody');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Admin delete department HTTP hatası: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      if (e is Exception) {
        debugPrint('❌ Exception details: $e');
      }
      return false;
    }
  }
}

/// Kapı modeli
class Gate {
  final int? gateId; // Veritabanı GateID
  final String? gateNumber;
  final String? terminal;
  final String? status;
  final String? currentFlight;
  final String? airportName;
  final String? airlineName;

  Gate({
    this.gateId,
    this.gateNumber,
    this.terminal,
    this.status,
    this.currentFlight,
    this.airportName,
    this.airlineName,
  });

  factory Gate.fromJson(Map<String, dynamic> json) {
    return Gate(
      gateId: json['GateID'] as int?,
      gateNumber: json['GateNo'] as String?,
      terminal: json['Terminal'] as String?,
      status: json['Status'] as String?,
      currentFlight: json['FlightCode'] as String?,
      airportName: json['AirportName'] as String?,
      airlineName: json['AirlineName'] as String?,
    );
  }
}

/// Bugünkü uçuş modeli
class TodayFlight {
  final String id;
  final String flightNo;
  final String departure;
  final String arrival;
  final String status;

  TodayFlight({
    required this.id,
    required this.flightNo,
    required this.departure,
    required this.arrival,
    required this.status,
  });

  factory TodayFlight.fromJson(Map<String, dynamic> json) {
    return TodayFlight(
      id: json['id'] as String? ?? '',
      flightNo: json['flightNo'] as String? ?? '',
      departure: json['departure'] as String? ?? '',
      arrival: json['arrival'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}

/// Departman modeli
class Employee {
  final int? employeeId;
  final String? firstName;
  final String? lastName;
  final int? departmentId;
  final String? departmentName;
  final double? salary;
  final String? contact;
  final String? role;

  Employee({
    this.employeeId,
    this.firstName,
    this.lastName,
    this.departmentId,
    this.departmentName,
    this.salary,
    this.contact,
    this.role,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      employeeId: json['EmployeeID'] as int?,
      firstName: json['FirstName'] as String?,
      lastName: json['LastName'] as String?,
      departmentId: json['DepartmentID'] as int?,
      departmentName: json['DepartmentName'] as String?,
      salary: (json['Salary'] as num?)?.toDouble(),
      contact: json['Contact'] as String?,
      role: json['Role'] as String?,
    );
  }
}

class Department {
  final int? departmentId;
  final String? departmentName;
  final String? description;
  final int? departmentManagerId;
  final String? manager;

  Department({
    this.departmentId,
    this.departmentName,
    this.description,
    this.departmentManagerId,
    this.manager,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      departmentId: json['DepartmentID'] as int?,
      departmentName: json['DepartmentName'] as String?,
      description: json['Description'] as String?,
      departmentManagerId: json['DepartmentManagerID'] as int?,
      manager: json['Manager'] as String?,
    );
  }
}

class ActivityLog {
  final int? logId;
  final String? userName;
  final String? action;
  final String? description;
  final String? logDate;

  ActivityLog({
    this.logId,
    this.userName,
    this.action,
    this.description,
    this.logDate,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      logId: json['LogID'] as int?,
      userName: json['UserName'] as String?,
      action: json['Action'] as String?,
      description: json['Description'] as String?,
      logDate: json['LogDate']?.toString(),
    );
  }
}

class Reservation {
  final int? reservationId;
  final String? reservationCode;
  final String? reservationDate;
  final String? reservationStatus;
  final double? totalAmount;
  final String? customerName;
  final String? email;
  final String? phone;
  final int? flightId;
  final String? flightCode;
  final String? departureTime;
  final String? arrivalTime;
  final String? departureAirport;
  final String? arrivalAirport;
  final String? passengerName;
  final String? seatNumber;
  final int? ticketNo;
  final String? flightClass;
  final String? paymentMethod;
  final int? passengerCount;

  Reservation({
    this.reservationId,
    this.reservationCode,
    this.reservationDate,
    this.reservationStatus,
    this.totalAmount,
    this.customerName,
    this.email,
    this.phone,
    this.flightId,
    this.flightCode,
    this.departureTime,
    this.arrivalTime,
    this.departureAirport,
    this.arrivalAirport,
    this.passengerName,
    this.seatNumber,
    this.ticketNo,
    this.flightClass,
    this.paymentMethod,
    this.passengerCount,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      reservationId: json['ReservationID'] as int?,
      reservationCode: json['ReservationCode'] as String?,
      reservationDate: json['ReservationDate']?.toString(),
      reservationStatus: json['ReservationStatus'] as String?,
      totalAmount: (json['TotalAmount'] as num?)?.toDouble(),
      customerName: json['CustomerName'] as String?,
      email: json['Email'] as String?,
      phone: json['Phone'] as String?,
      flightId: json['FlightID'] as int?,
      flightCode: json['FlightCode'] as String?,
      departureTime: json['DepartureTime']?.toString(),
      arrivalTime: json['ArrivalTime']?.toString(),
      departureAirport: json['DepartureAirport'] as String?,
      arrivalAirport: json['ArrivalAirport'] as String?,
      passengerName: json['PassengerName'] as String?,
      seatNumber: json['SeatNumber'] as String?,
      ticketNo: json['TicketNo'] as int?,
      flightClass: json['FlightClass'] as String?,
      paymentMethod: json['PaymentMethod'] as String?,
      passengerCount: json['PassengerCount'] as int?,
    );
  }
}

/// Araç Tipi modeli
class VehicleType {
  final int? typeId;
  final String? typeName;
  final double? priceMultiplier;

  VehicleType({
    this.typeId,
    this.typeName,
    this.priceMultiplier,
  });

  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      typeId: json['TypeID'] as int?,
      typeName: json['TypeName'] as String?,
      priceMultiplier: (json['PriceMultiplier'] as num?)?.toDouble(),
    );
  }
}

/// Yolcu modeli
class Passenger {
  final int? passengerId;
  final String? firstName;
  final String? lastName;
  final String? passportNo;
  final int? age;
  final String? gender;
  final String? nationality;
  final int? reservationId;
  final String? reservationCode;
  final String? reservationDate;
  final String? reservationStatus;
  final double? totalAmount;
  final int? customerUserId;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final int? flightId;
  final String? flightCode;
  final String? departureTime;
  final String? arrivalTime;
  final String? departureAirport;
  final String? arrivalAirport;
  final int? ticketId;
  final String? boardingGate;
  final String? ticketStatus;
  final int? seatId;
  final String? seatNumber;
  final int? classId;
  final String? flightClass;

  Passenger({
    this.passengerId,
    this.firstName,
    this.lastName,
    this.passportNo,
    this.age,
    this.gender,
    this.nationality,
    this.reservationId,
    this.reservationCode,
    this.reservationDate,
    this.reservationStatus,
    this.totalAmount,
    this.customerUserId,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.flightId,
    this.flightCode,
    this.departureTime,
    this.arrivalTime,
    this.departureAirport,
    this.arrivalAirport,
    this.ticketId,
    this.boardingGate,
    this.ticketStatus,
    this.seatId,
    this.seatNumber,
    this.classId,
    this.flightClass,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      passengerId: json['PassengerID'] as int?,
      firstName: json['FirstName'] as String?,
      lastName: json['LastName'] as String?,
      passportNo: json['PassportNo'] as String?,
      age: json['Age'] as int?,
      gender: json['Gender'] as String?,
      nationality: json['Nationality'] as String?,
      reservationId: json['ReservationID'] as int?,
      reservationCode: json['ReservationCode'] as String?,
      reservationDate: json['ReservationDate']?.toString(),
      reservationStatus: json['ReservationStatus'] as String?,
      totalAmount: (json['TotalAmount'] as num?)?.toDouble(),
      customerUserId: json['CustomerUserID'] as int?,
      customerName: json['CustomerName'] as String?,
      customerEmail: json['CustomerEmail'] as String?,
      customerPhone: json['CustomerPhone'] as String?,
      flightId: json['FlightID'] as int?,
      flightCode: json['FlightCode'] as String?,
      departureTime: json['DepartureTime']?.toString(),
      arrivalTime: json['ArrivalTime']?.toString(),
      departureAirport: json['DepartureAirport'] as String?,
      arrivalAirport: json['ArrivalAirport'] as String?,
      ticketId: json['TicketID'] as int?,
      boardingGate: json['BoardingGate'] as String?,
      ticketStatus: json['TicketStatus'] as String?,
      seatId: json['SeatID'] as int?,
      seatNumber: json['SeatNumber'] as String?,
      classId: json['ClassID'] as int?,
      flightClass: json['FlightClass'] as String?,
    );
  }
}

