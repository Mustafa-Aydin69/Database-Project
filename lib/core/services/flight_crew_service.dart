import 'package:http/http.dart' as http;
import 'dart:convert';

class FlightCrewItem {
  final int crewID;
  final String flight;
  final String employee;
  final int employeeID;
  final String role;

  FlightCrewItem({
    required this.crewID,
    required this.flight,
    required this.employee,
    required this.employeeID,
    required this.role,
  });

  factory FlightCrewItem.fromJson(Map<String, dynamic> json) {
    return FlightCrewItem(
      crewID: json['crewID'] is int
          ? json['crewID']
          : int.tryParse('${json['crewID']}') ?? DateTime.now().millisecondsSinceEpoch,
      flight: json['flight'] ?? '',
      employee: json['employee'] ?? '',
      employeeID: json['employeeID'] is int ? json['employeeID'] : 0,
      role: json['role'] ?? '',
    );
  }
}

class FlightCrewService {
  static final FlightCrewService _instance = FlightCrewService._internal();
  factory FlightCrewService() => _instance;
  FlightCrewService._internal();

  static const String _listUrl = 'http://localhost:3080/api/flight-crew/list';
  static const String _deleteUrl = 'http://localhost:3080/api/flight-crew/delete-by-employee';
  static const String _flightsUrl = 'http://localhost:3080/api/flight-crew/flights';
  static const String _employeesUrl = 'http://localhost:3080/api/flight-crew/employees';
  static const String _rolesUrl = 'http://localhost:3080/api/flight-crew/roles';
  static const String _addUrl = 'http://localhost:3080/api/flight-crew/add';

  Future<List<FlightCrewItem>> fetchCrewList() async {
    try {
      final res = await http.get(Uri.parse(_listUrl), headers: {'Content-Type': 'application/json'});
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final List<dynamic> data = body['data'] ?? [];
        return data.map((e) => FlightCrewItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchFlights() async {
    try {
      final res = await http.get(Uri.parse(_flightsUrl));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        return List<Map<String, dynamic>>.from(body['data'] ?? []);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchEmployees() async {
    try {
      final res = await http.get(Uri.parse(_employeesUrl));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        return List<Map<String, dynamic>>.from(body['data'] ?? []);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> fetchRoles() async {
    try {
      final res = await http.get(Uri.parse(_rolesUrl));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final data = body['data'] as List;
        return data.map((e) => e['RoleName'].toString()).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> addCrew(int flightID, int employeeID, String role) async {
    try {
      final res = await http.post(
        Uri.parse(_addUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'flightID': flightID,
          'employeeID': employeeID,
          'role': role,
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCrewByEmployee(int employeeID) async {
    try {
      final res = await http.delete(
        Uri.parse('$_deleteUrl/$employeeID'),
        headers: {'Content-Type': 'application/json'},
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
