import 'package:http/http.dart' as http;
import 'dart:convert';

class FlightPriceItem {
  final int pricingID;
  final int flightID;
  final int classID;
  final double price;
  final String className;
  final String flightLabel;

  FlightPriceItem({
    required this.pricingID,
    required this.flightID,
    required this.classID,
    required this.price,
    required this.className,
    required this.flightLabel,
  });

  factory FlightPriceItem.fromJson(Map<String, dynamic> json) {
    return FlightPriceItem(
      pricingID: json['pricingID'] ?? 0,
      flightID: json['flightID'] ?? 0,
      classID: json['classID'] ?? 0,
      price: (json['price'] is int) ? (json['price'] as int).toDouble() : (json['price'] ?? 0.0),
      className: json['className'] ?? '',
      flightLabel: json['flightLabel'] ?? '',
    );
  }
}

class FlightPricingService {
  static final FlightPricingService _instance = FlightPricingService._internal();
  factory FlightPricingService() => _instance;
  FlightPricingService._internal();

  static const String _baseUrl = 'http://localhost:3080/api/flight-pricing';

  Future<List<FlightPriceItem>> fetchPrices() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/list'));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final List<dynamic> data = body['data'] ?? [];
        return data.map((e) => FlightPriceItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchFlights() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/flights'));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        return List<Map<String, dynamic>>.from(body['data'] ?? []);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchClasses() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/classes'));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        return List<Map<String, dynamic>>.from(body['data'] ?? []);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> addPrice(int flightID, int classID, double price) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'flightID': flightID,
          'classID': classID,
          'price': price,
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updatePrice(int id, int flightID, int classID, double price) async {
    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/update/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'flightID': flightID,
          'classID': classID,
          'price': price,
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deletePrice(int id) async {
    try {
      final res = await http.delete(Uri.parse('$_baseUrl/delete/$id'));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
