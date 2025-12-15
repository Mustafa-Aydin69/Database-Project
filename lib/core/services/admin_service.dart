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
  static const String _updateVehicleTypeApiUrl =
      'http://localhost:3000/api/admin/update-vehicle-type';
  static const String _parkingLotsApiUrl =
      'http://localhost:3000/api/admin/parking-lots';
  static const String _updateParkingLotApiUrl =
      'http://localhost:3000/api/admin/update-parking-lot';
  static const String _addParkingLotApiUrl =
      'http://localhost:3000/api/admin/add-parking-lot';
  static const String _parkingSpotsApiUrl =
      'http://localhost:3000/api/admin/parking-spots';
  static const String _updateParkingSpotApiUrl =
      'http://localhost:3000/api/admin/update-parking-spot';
  static const String _addParkingSpotApiUrl =
      'http://localhost:3000/api/admin/add-parking-spot';
  // Mobil (Android Emülatörü) için: 'http://10.0.2.2:3000/api/admin/...'
  // Mobil (Gerçek Cihaz) için: Bilgisayarınızın yerel IP adresi.

  static const String _deleteParkingSpotApiUrl =
      'http://localhost:3000/api/admin/delete-parking-spot';

  static const String _userVehiclesApiUrl =
      'http://localhost:3000/api/admin/user-vehicles';

  static const String _updateUserVehicleApiUrl =
      'http://localhost:3000/api/admin/update-user-vehicle';

  static const String _deleteUserVehicleApiUrl =
      'http://localhost:3000/api/admin/delete-user-vehicle';

  static const String _addUserVehicleApiUrl =
      'http://localhost:3000/api/admin/add-user-vehicle';
  static const String _parkingReservationsApiUrl =
      'http://localhost:3000/api/admin/parking-reservations';

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
      
      // http.delete() body parametresi desteklemediği için http.Request kullanıyoruz
      final request = http.Request('DELETE', Uri.parse(_deleteGateApiUrl));
      request.headers.addAll({'Content-Type': 'application/json'});
      request.body = json.encode({
        'gateId': gateId,
        'userId': userId,
      });
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

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
      
      // http.delete() body parametresi desteklemediği için http.Request kullanıyoruz
      final request = http.Request('DELETE', Uri.parse(_deleteEmployeeApiUrl));
      request.headers.addAll({'Content-Type': 'application/json'});
      request.body = json.encode({
        'employeeId': employeeId,
        'userId': userId,
      });
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

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

  /// Tüm otopark alanlarını getirir
  /// Başarılıysa List<ParkingLot>, başarısızsa boş liste döner
  Future<List<ParkingLot>> getParkingLots() async {
    try {
      debugPrint('📡 Calling parking lots API: $_parkingLotsApiUrl');
      final response = await http.get(
        Uri.parse(_parkingLotsApiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin parking lots API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        return [];
      }

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // API'den gelen data listesini ParkingLot modeline dönüştür
        final data = responseBody['data'] as List<dynamic>?;
        debugPrint('📥 Admin parking lots API: ${data?.length ?? 0} parking lots retrieved');
        if (data != null && data.isNotEmpty) {
          debugPrint('📋 First parking lot sample: ${data[0]}');
          final parkingLots = data.map((item) => ParkingLot.fromJson(item as Map<String, dynamic>)).toList();
          debugPrint('✅ Parsed ${parkingLots.length} parking lots successfully');
          return parkingLots;
        }
        debugPrint('⚠️ API returned empty data array');
        return [];
      }

      debugPrint('⚠️ API response not successful: status=${response.statusCode}, success=${responseBody['success']}');

      // Hata durumunda boş liste döndür
      debugPrint('⚠️ Admin parking lots API hatası: ${response.statusCode}');
      return [];
    } catch (e) {
      // Ağ bağlantısı hatası
      debugPrint('❌ Admin parking lots HTTP hatası: $e');
      return [];
    }
  }

  /// Otopark alanını günceller (sadece Capacity ve LocationDescription)
  /// Başarılıysa true, başarısızsa false döner
  /// LotName ve AirportID değiştirilemez
  Future<bool> updateParkingLot({
    required int parkingLotId,
    required int capacity,
    String? locationDescription,
    required int userId,
  }) async {
    try {
      debugPrint('📡 Calling update parking lot API: $_updateParkingLotApiUrl');

      final requestBody = {
        'parkingLotId': parkingLotId,
        'capacity': capacity,
        'locationDescription': locationDescription,
        'userId': userId,
      };

      debugPrint('📋 Update parking lot request body: $requestBody');

      final response = await http.put(
        Uri.parse(_updateParkingLotApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      debugPrint('📡 Update parking lot API response: status=${response.statusCode}, body length=${response.body.length}');

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        debugPrint('✅ Parking lot updated successfully');
        return true;
      }

      debugPrint('⚠️ Update parking lot API response not successful: status=${response.statusCode}, success=${responseBody['success']}');
      debugPrint('⚠️ Error message: ${responseBody['message'] ?? 'Bilinmeyen hata'}');
      return false;
    } catch (e) {
      debugPrint('❌ Update parking lot HTTP hatası: $e');
      return false;
    }
  }

  /// Yeni otopark alanı ekler
  /// Başarılıysa true ve ParkingLotID döner, başarısızsa false döner
  /// AirportID, LotName ve Capacity zorunludur
  Future<Map<String, dynamic>> addParkingLot({
    required int airportId,
    required String lotName,
    required int capacity,
    String? locationDescription,
    required int userId,
  }) async {
    try {
      debugPrint('📡 Calling add parking lot API: $_addParkingLotApiUrl');

      final requestBody = {
        'airportId': airportId,
        'lotName': lotName.trim(),
        'capacity': capacity,
        'locationDescription': locationDescription?.trim(),
        'userId': userId,
      };

      debugPrint('📋 Add parking lot request body: $requestBody');

      final response = await http.post(
        Uri.parse(_addParkingLotApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      debugPrint('📡 Add parking lot API response: status=${response.statusCode}, body length=${response.body.length}');

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final parkingLotId = responseBody['data']?['parkingLotId'];
        debugPrint('✅ Parking lot added successfully. ParkingLotID: $parkingLotId');
        return {
          'success': true,
          'parkingLotId': parkingLotId,
        };
      }

      debugPrint('⚠️ Add parking lot API response not successful: status=${response.statusCode}, success=${responseBody['success']}');
      debugPrint('⚠️ Error message: ${responseBody['message'] ?? 'Bilinmeyen hata'}');
      return {
        'success': false,
        'message': responseBody['message'] ?? 'Otopark alanı eklenirken bir hata oluştu',
      };
    } catch (e) {
      debugPrint('❌ Add parking lot HTTP hatası: $e');
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }

  /// Tüm park yerlerini getirir
  /// Başarılıysa List<ParkingSpot>, başarısızsa boş liste döner
  Future<List<ParkingSpot>> getParkingSpots() async {
    try {
      debugPrint('📡 Calling parking spots API: $_parkingSpotsApiUrl');
      final response = await http.get(
        Uri.parse(_parkingSpotsApiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin parking spots API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        return [];
      }

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // API'den gelen data listesini ParkingSpot modeline dönüştür
        final data = responseBody['data'] as List<dynamic>?;
        debugPrint('📥 Admin parking spots API: ${data?.length ?? 0} parking spots retrieved');
        if (data != null && data.isNotEmpty) {
          debugPrint('📋 First parking spot sample: ${data[0]}');
          final parkingSpots = data.map((item) => ParkingSpot.fromJson(item as Map<String, dynamic>)).toList();
          debugPrint('✅ Parsed ${parkingSpots.length} parking spots successfully');
          return parkingSpots;
        }
        debugPrint('⚠️ API returned empty data array');
        return [];
      }

      debugPrint('⚠️ API response not successful: status=${response.statusCode}, success=${responseBody['success']}');

      // Hata durumunda boş liste döndür
      debugPrint('⚠️ Admin parking spots API hatası: ${response.statusCode}');
      return [];
    } catch (e) {
      // Ağ bağlantısı hatası
      debugPrint('❌ Admin parking spots HTTP hatası: $e');
      return [];
    }
  }

  /// Park yerini günceller (sadece IsReserved)
  /// Başarılıysa true, başarısızsa false döner
  /// ParkingLotID ve SpotNumber değiştirilemez
  Future<bool> updateParkingSpot({
    required int spotId,
    required bool isReserved,
    required int userId,
  }) async {
    try {
      debugPrint('📡 Calling update parking spot API: $_updateParkingSpotApiUrl');

      final requestBody = {
        'spotId': spotId,
        'isReserved': isReserved,
        'userId': userId,
      };

      debugPrint('📋 Update parking spot request body: $requestBody');

      final response = await http.put(
        Uri.parse(_updateParkingSpotApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      debugPrint('📡 Update parking spot API response: status=${response.statusCode}, body length=${response.body.length}');

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        debugPrint('✅ Parking spot updated successfully');
        return true;
      }

      debugPrint('⚠️ Update parking spot API response not successful: status=${response.statusCode}, success=${responseBody['success']}');
      debugPrint('⚠️ Error message: ${responseBody['message'] ?? 'Bilinmeyen hata'}');
      return false;
    } catch (e) {
      debugPrint('❌ Update parking spot HTTP hatası: $e');
      return false;
    }
  }

  /// Yeni park yeri ekler
  /// Başarılıysa true ve SpotID döner, başarısızsa false döner
  /// ParkingLotID, SpotNumber ve IsReserved zorunludur
  Future<Map<String, dynamic>> addParkingSpot({
    required int parkingLotId,
    required String spotNumber,
    required bool isReserved,
    required int userId,
  }) async {
    try {
      debugPrint('📡 Calling add parking spot API: $_addParkingSpotApiUrl');

      final requestBody = {
        'parkingLotId': parkingLotId,
        'spotNumber': spotNumber.trim(),
        'isReserved': isReserved,
        'userId': userId,
      };

      debugPrint('📋 Add parking spot request body: $requestBody');

      final response = await http.post(
        Uri.parse(_addParkingSpotApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      debugPrint('📡 Add parking spot API response: status=${response.statusCode}, body length=${response.body.length}');

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final spotId = responseBody['data']?['spotId'];
        debugPrint('✅ Parking spot added successfully. SpotID: $spotId');
        return {
          'success': true,
          'spotId': spotId,
        };
      }

      debugPrint('⚠️ Add parking spot API response not successful: status=${response.statusCode}, success=${responseBody['success']}');
      debugPrint('⚠️ Error message: ${responseBody['message'] ?? 'Bilinmeyen hata'}');
      return {
        'success': false,
        'message': responseBody['message'] ?? 'Park yeri eklenirken bir hata oluştu',
      };
    } catch (e) {
      debugPrint('❌ Add parking spot HTTP hatası: $e');
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }

  /// Park yeri siler
  /// Başarılıysa true, başarısızsa false döner
  Future<bool> deleteParkingSpot({
    required int spotId,
    required int userId,
  }) async {
    try {
      debugPrint('📡 Calling delete parking spot API: $_deleteParkingSpotApiUrl');
      debugPrint('📋 Delete data: spotId=$spotId, userId=$userId');
      
      // http.delete() body parametresi desteklemediği için http.Request kullanıyoruz
      final request = http.Request('DELETE', Uri.parse(_deleteParkingSpotApiUrl));
      request.headers.addAll({'Content-Type': 'application/json'});
      request.body = json.encode({
        'spotId': spotId,
        'userId': userId,
      });
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📡 Delete parking spot API response: status=${response.statusCode}, body length=${response.body.length}');

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin delete parking spot API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        debugPrint('⚠️ Response body (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
        return false;
      }

      final responseBody = json.decode(response.body);
      debugPrint('📥 Delete parking spot API response body (parsed): $responseBody');

      if (response.statusCode == 200 && responseBody['success'] == true) {
        debugPrint('✅ Parking spot deleted successfully');
        return true;
      } else {
        final errorMessage = responseBody['message'] ?? 'Bilinmeyen hata';
        debugPrint('⚠️ Delete parking spot API response not successful: status=${response.statusCode}, message=$errorMessage');
        debugPrint('⚠️ Full response body: $responseBody');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Admin delete parking spot HTTP hatası: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      if (e is Exception) {
        debugPrint('❌ Exception details: $e');
      }
      return false;
    }
  }

  /// Kullanıcı araçlarını getirir
  /// Başarılıysa List<UserVehicle>, başarısızsa boş liste döner
  Future<List<UserVehicle>> getUserVehicles() async {
    try {
      debugPrint('📡 Calling user vehicles API: $_userVehiclesApiUrl');
      final response = await http.get(
        Uri.parse(_userVehiclesApiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin user vehicles API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        return [];
      }

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // API'den gelen data listesini UserVehicle modeline dönüştür
        final data = responseBody['data'] as List<dynamic>?;
        debugPrint('📥 Admin user vehicles API: ${data?.length ?? 0} vehicles retrieved');
        if (data != null && data.isNotEmpty) {
          debugPrint('📋 First vehicle sample: ${data[0]}');
          final vehicles = data.map((item) => UserVehicle.fromJson(item as Map<String, dynamic>)).toList();
          debugPrint('✅ Parsed ${vehicles.length} vehicles successfully');
          return vehicles;
        }
        debugPrint('⚠️ API returned empty data array');
        return [];
      }
      
      debugPrint('⚠️ API response not successful: status=${response.statusCode}, success=${responseBody['success']}');

      // Hata durumunda boş liste döndür
      debugPrint('⚠️ Admin user vehicles API hatası: ${response.statusCode}');
      return [];
    } catch (e) {
      // Ağ bağlantısı hatası
      debugPrint('❌ Admin user vehicles HTTP hatası: $e');
      return [];
    }
  }

  /// Otopark rezervasyonlarını getirir
  Future<List<ParkingReservation>> getParkingReservations() async {
    try {
      debugPrint('📡 Calling parking reservations API: $_parkingReservationsApiUrl');
      final response = await http.get(
        Uri.parse(_parkingReservationsApiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin parking reservations API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        return [];
      }

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // API'den gelen data listesini ParkingReservation modeline dönüştür
        final data = responseBody['data'] as List<dynamic>?;
        debugPrint('📥 Admin parking reservations API: ${data?.length ?? 0} reservations retrieved');
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
      debugPrint('⚠️ Admin parking reservations API hatası: ${response.statusCode}');
      return [];
    } catch (e) {
      // Ağ bağlantısı hatası
      debugPrint('❌ Admin parking reservations HTTP hatası: $e');
      return [];
    }
  }

  /// Kullanıcı aracı günceller
  /// Başarılıysa true, başarısızsa false döner
  Future<bool> updateUserVehicle({
    required int vehicleId,
    required int userId,
    required int typeId,
    required String plateNumber,
    required int logUserId,
  }) async {
    try {
      debugPrint('📡 Calling update user vehicle API: $_updateUserVehicleApiUrl');

      final requestBody = {
        'vehicleId': vehicleId,
        'userId': userId,
        'typeId': typeId,
        'plateNumber': plateNumber.trim(),
        'logUserId': logUserId,
      };

      debugPrint('📋 Update user vehicle request body: $requestBody');

      final response = await http.put(
        Uri.parse(_updateUserVehicleApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      debugPrint('📡 Update user vehicle API response: status=${response.statusCode}, body length=${response.body.length}');

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        debugPrint('✅ User vehicle updated successfully');
        return true;
      }

      debugPrint('⚠️ Update user vehicle API response not successful: status=${response.statusCode}, success=${responseBody['success']}');
      debugPrint('⚠️ Error message: ${responseBody['message'] ?? 'Bilinmeyen hata'}');
      return false;
    } catch (e) {
      debugPrint('❌ Update user vehicle HTTP hatası: $e');
      return false;
    }
  }

  /// Kullanıcı aracı siler
  /// Başarılıysa true, başarısızsa false döner
  Future<bool> deleteUserVehicle({
    required int vehicleId,
    required int logUserId,
  }) async {
    try {
      debugPrint('📡 Calling delete user vehicle API: $_deleteUserVehicleApiUrl');
      debugPrint('📋 Delete data: vehicleId=$vehicleId, logUserId=$logUserId');
      
      // http.delete() body parametresi desteklemediği için http.Request kullanıyoruz
      final request = http.Request('DELETE', Uri.parse(_deleteUserVehicleApiUrl));
      request.headers.addAll({'Content-Type': 'application/json'});
      request.body = json.encode({
        'vehicleId': vehicleId,
        'logUserId': logUserId,
      });
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📡 Delete user vehicle API response: status=${response.statusCode}, body length=${response.body.length}');

      // Response body'nin JSON olup olmadığını kontrol et
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('⚠️ Admin delete user vehicle API: JSON olmayan response alındı. Status: ${response.statusCode}, Content-Type: $contentType');
        debugPrint('⚠️ Response body (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
        return false;
      }

      final responseBody = json.decode(response.body);
      debugPrint('📥 Delete user vehicle API response body (parsed): $responseBody');

      if (response.statusCode == 200 && responseBody['success'] == true) {
        debugPrint('✅ User vehicle deleted successfully');
        return true;
      } else {
        final errorMessage = responseBody['message'] ?? 'Bilinmeyen hata';
        debugPrint('⚠️ Delete user vehicle API response not successful: status=${response.statusCode}, message=$errorMessage');
        debugPrint('⚠️ Full response body: $responseBody');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Admin delete user vehicle HTTP hatası: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      if (e is Exception) {
        debugPrint('❌ Exception details: $e');
      }
      return false;
    }
  }

  /// Yeni kullanıcı aracı ekler
  /// Başarılıysa Map<String, dynamic> (success, vehicleId), başarısızsa (success: false, message) döner
  Future<Map<String, dynamic>> addUserVehicle({
    required int userId,
    required int typeId,
    required String plateNumber,
    required int logUserId,
  }) async {
    try {
      debugPrint('📡 Calling add user vehicle API: $_addUserVehicleApiUrl');

      final requestBody = {
        'userId': userId,
        'typeId': typeId,
        'plateNumber': plateNumber.trim(),
        'logUserId': logUserId,
      };

      debugPrint('📋 Add user vehicle request body: $requestBody');

      final response = await http.post(
        Uri.parse(_addUserVehicleApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      debugPrint('📡 Add user vehicle API response: status=${response.statusCode}, body length=${response.body.length}');

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final vehicleId = responseBody['data']?['vehicleId'];
        debugPrint('✅ User vehicle added successfully. VehicleID: $vehicleId');
        return {
          'success': true,
          'vehicleId': vehicleId,
        };
      }

      debugPrint('⚠️ Add user vehicle API response not successful: status=${response.statusCode}, success=${responseBody['success']}');
      debugPrint('⚠️ Error message: ${responseBody['message'] ?? 'Bilinmeyen hata'}');
      return {
        'success': false,
        'message': responseBody['message'] ?? 'Araç eklenirken bir hata oluştu',
      };
    } catch (e) {
      debugPrint('❌ Add user vehicle HTTP hatası: $e');
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }

  /// Araç tipinin fiyat çarpanını günceller
  /// Başarılıysa true, başarısızsa false döner
  /// TypeName değiştirilemez, sadece PriceMultiplier güncellenir
  Future<bool> updateVehicleType({
    required int typeId,
    required double priceMultiplier,
    required int userId,
  }) async {
    try {
      debugPrint('📡 Calling update vehicle type API: $_updateVehicleTypeApiUrl');
      
      final requestBody = {
        'typeId': typeId,
        'priceMultiplier': priceMultiplier,
        'userId': userId,
      };

      debugPrint('📋 Update vehicle type request body: $requestBody');

      final response = await http.put(
        Uri.parse(_updateVehicleTypeApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      debugPrint('📡 Update vehicle type API response: status=${response.statusCode}, body length=${response.body.length}');

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        debugPrint('✅ Vehicle type updated successfully');
        return true;
      }

      debugPrint('⚠️ Update vehicle type API response not successful: status=${response.statusCode}, success=${responseBody['success']}');
      debugPrint('⚠️ Error message: ${responseBody['message'] ?? 'Bilinmeyen hata'}');
      return false;
    } catch (e) {
      debugPrint('❌ Update vehicle type HTTP hatası: $e');
      return false;
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

      // http.delete() body parametresi desteklemediği için http.Request kullanıyoruz
      final request = http.Request('DELETE', Uri.parse(_deletePassengerApiUrl));
      request.headers.addAll({'Content-Type': 'application/json'});
      request.body = json.encode(requestBody);
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

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
      
      // http.delete() body parametresi desteklemediği için http.Request kullanıyoruz
      final request = http.Request('DELETE', Uri.parse(_deleteReservationApiUrl));
      request.headers.addAll({'Content-Type': 'application/json'});
      request.body = json.encode({
        'reservationId': reservationId,
        'userId': userId,
      });
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

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
      
      // http.delete() body parametresi desteklemediği için http.Request kullanıyoruz
      final request = http.Request('DELETE', Uri.parse(_deleteDepartmentApiUrl));
      request.headers.addAll({'Content-Type': 'application/json'});
      request.body = json.encode({
        'departmentId': departmentId,
        'userId': userId,
      });
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

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

/// Kullanıcı Aracı modeli
class UserVehicle {
  final int? vehicleId;
  final String? plateNumber;
  final int? userId;
  final String? userName;
  final String? userEmail;
  final int? typeId;
  final String? typeName;

  UserVehicle({
    this.vehicleId,
    this.plateNumber,
    this.userId,
    this.userName,
    this.userEmail,
    this.typeId,
    this.typeName,
  });

  factory UserVehicle.fromJson(Map<String, dynamic> json) {
    return UserVehicle(
      vehicleId: json['vehicleID'] as int?,
      plateNumber: json['plateNumber'] as String?,
      userId: json['userID'] as int?,
      userName: json['userName'] as String?,
      userEmail: json['userEmail'] as String?,
      typeId: json['typeID'] as int?,
      typeName: json['typeName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleID': vehicleId,
      'plateNumber': plateNumber,
      'userID': userId,
      'userName': userName,
      'userEmail': userEmail,
      'typeID': typeId,
      'typeName': typeName,
    };
  }
}

/// Otopark Alanı modeli
class ParkingLot {
  final int? parkingLotId;
  final int? airportId;
  final String? lotName;
  final int? capacity;
  final String? locationDescription;
  final String? airportName;
  final String? airportIATACode;
  final String? airportCity;
  final int? occupiedSpots;

  ParkingLot({
    this.parkingLotId,
    this.airportId,
    this.lotName,
    this.capacity,
    this.locationDescription,
    this.airportName,
    this.airportIATACode,
    this.airportCity,
    this.occupiedSpots,
  });

  factory ParkingLot.fromJson(Map<String, dynamic> json) {
    return ParkingLot(
      parkingLotId: json['ParkingLotID'] as int?,
      airportId: json['AirportID'] as int?,
      lotName: json['LotName'] as String?,
      capacity: json['Capacity'] as int?,
      locationDescription: json['LocationDescription'] as String?,
      airportName: json['AirportName'] as String?,
      airportIATACode: json['AirportIATACode'] as String?,
      airportCity: json['AirportCity'] as String?,
      occupiedSpots: json['OccupiedSpots'] as int?,
    );
  }
}

/// Park Yeri modeli
class ParkingSpot {
  final int? spotId;
  final int? parkingLotId;
  final String? spotNumber;
  final bool? isReserved;
  final String? parkingLotName;
  final int? parkingLotCapacity;
  final String? parkingLotLocation;
  final int? airportId;
  final String? airportName;
  final String? airportIATACode;
  final String? airportCity;
  final String? airportDisplayName;

  ParkingSpot({
    this.spotId,
    this.parkingLotId,
    this.spotNumber,
    this.isReserved,
    this.parkingLotName,
    this.parkingLotCapacity,
    this.parkingLotLocation,
    this.airportId,
    this.airportName,
    this.airportIATACode,
    this.airportCity,
    this.airportDisplayName,
  });

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      spotId: json['SpotID'] as int?,
      parkingLotId: json['ParkingLotID'] as int?,
      spotNumber: json['SpotNumber'] as String?,
      isReserved: json['IsReserved'] as bool?,
      parkingLotName: json['ParkingLotName'] as String?,
      parkingLotCapacity: json['ParkingLotCapacity'] as int?,
      parkingLotLocation: json['ParkingLotLocation'] as String?,
      airportId: json['AirportID'] as int?,
      airportName: json['AirportName'] as String?,
      airportIATACode: json['AirportIATACode'] as String?,
      airportCity: json['AirportCity'] as String?,
      airportDisplayName: json['AirportDisplayName'] as String?,
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

/// Otopark Rezervasyonu modeli
class ParkingReservation {
  final int? parkingReservationId;
  final String? checkInTime;
  final String? checkOutTime;
  final String? status;
  final int? userId;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final int? spotId;
  final String? spotNumber;
  final bool? isReserved;
  final int? parkingLotId;
  final String? parkingLotName;
  final int? parkingLotCapacity;
  final String? parkingLotLocation;
  final int? airportId;
  final String? airportName;
  final String? airportIATACode;
  final String? airportCity;
  final String? airportCountry;
  final String? airportDisplayName;
  final int? vehicleId;
  final String? plateNumber;
  final int? typeId;
  final String? vehicleTypeName;
  final double? vehiclePriceMultiplier;

  ParkingReservation({
    this.parkingReservationId,
    this.checkInTime,
    this.checkOutTime,
    this.status,
    this.userId,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.spotId,
    this.spotNumber,
    this.isReserved,
    this.parkingLotId,
    this.parkingLotName,
    this.parkingLotCapacity,
    this.parkingLotLocation,
    this.airportId,
    this.airportName,
    this.airportIATACode,
    this.airportCity,
    this.airportCountry,
    this.airportDisplayName,
    this.vehicleId,
    this.plateNumber,
    this.typeId,
    this.vehicleTypeName,
    this.vehiclePriceMultiplier,
  });

  factory ParkingReservation.fromJson(Map<String, dynamic> json) {
    return ParkingReservation(
      parkingReservationId: json['parkingReservationID'] as int?,
      checkInTime: json['checkInTime']?.toString(),
      checkOutTime: json['checkOutTime']?.toString(),
      status: json['status'] as String?,
      userId: json['userID'] as int?,
      userName: json['userName'] as String?,
      userEmail: json['userEmail'] as String?,
      userPhone: json['userPhone'] as String?,
      spotId: json['spotID'] as int?,
      spotNumber: json['spotNumber'] as String?,
      isReserved: json['isReserved'] as bool?,
      parkingLotId: json['parkingLotID'] as int?,
      parkingLotName: json['parkingLotName'] as String?,
      parkingLotCapacity: json['parkingLotCapacity'] as int?,
      parkingLotLocation: json['parkingLotLocation'] as String?,
      airportId: json['airportID'] as int?,
      airportName: json['airportName'] as String?,
      airportIATACode: json['airportIATACode'] as String?,
      airportCity: json['airportCity'] as String?,
      airportCountry: json['airportCountry'] as String?,
      airportDisplayName: json['airportDisplayName'] as String?,
      vehicleId: json['vehicleID'] as int?,
      plateNumber: json['plateNumber'] as String?,
      typeId: json['typeID'] as int?,
      vehicleTypeName: json['vehicleTypeName'] as String?,
      vehiclePriceMultiplier: (json['vehiclePriceMultiplier'] as num?)?.toDouble(),
    );
  }

  /// Map formatına dönüştür (UI için)
  Map<String, dynamic> toMap() {
    return {
      'parkingReservationID': parkingReservationId,
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'status': status,
      'userID': userId,
      'userName': userName,
      'userEmail': userEmail,
      'spotID': spotId,
      'spotNumber': spotNumber,
      'vehicleID': vehicleId,
      'plateNumber': plateNumber,
    };
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

