import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
class AirlineItem {
  final int id;
  final String name;
  AirlineItem({required this.id, required this.name});
}
class AirportItem {
  final int id;
  final String name;
  final String city;
  final String country;
  final String iata;
  AirportItem({required this.id, required this.name, required this.city, required this.country, required this.iata});
}
class AircraftItem {
  final int id;
  final String model;
  final int capacity;
  AircraftItem({required this.id, required this.model, required this.capacity});
}

class FlightsScreen extends StatefulWidget {
  const FlightsScreen({super.key});

  @override
  State<FlightsScreen> createState() => _FlightsScreenState();
}

class _FlightsScreenState extends State<FlightsScreen> {
  @override
  void initState() {
    super.initState();
    _fetchAirlinesAdmin();
    _fetchAirportsAdmin();
    _fetchFlights();
  }
  @override
  void dispose() {
    _departureDateController.dispose();

    _arrivalDateController.dispose();

    super.dispose();
  }

  // --- STATE ---

  int _currentPage = 0;

  final int _itemsPerPage = 10;

  String _searchTerm = "";

  String _filterAirline = "";

  String _filterStatus = "";

  // --- FORM KONTROLCÜLERİ ---

  final _formKey = GlobalKey<FormState>();

  String? _selectedAirline;

  String? _selectedAircraft;

  String? _selectedDepAirport;

  String? _selectedArrAirport;

  String _selectedStatus = 'Scheduled';

  // Tarih/Saat Kontrolcüleri (String olarak tutuyoruz ama DatePicker ile dolduracağız)

  DateTime? _departureDate;

  DateTime? _arrivalDate;

  final TextEditingController _departureDateController =
      TextEditingController();

  final TextEditingController _arrivalDateController = TextEditingController();

  // --- SABİT LİSTELER ---

  final List<String> _airlines = [];

  final List<String> _aircrafts = [
    'Boeing 737-800',

    'Airbus A320',

    'Boeing 777-300ER',

    'Airbus A350',
  ];

  final List<String> _airports = [
    'IST - İstanbul Havalimanı',

    'SAW - Sabiha Gökçen',

    'AYT - Antalya Havalimanı',

    'ADB - İzmir Adnan Menderes',

    'ESB - Esenboğa',

    'TZX - Trabzon',

    'JFK - New York JFK',
  ];

  final List<String> _statuses = [
    'Scheduled',
    'Delayed',
    'Completed',
    'Canceled',
  ];

  // --- MOCK VERİLER (React'ten alındı) ---

  List<Map<String, dynamic>> _flights = [];

  final List<AirlineItem> _airlineItems = [];
  final List<AirportItem> _airportItems = [];
  List<AircraftItem> _aircraftItems = [];
  int? _selectedAirlineId;
  int? _selectedAircraftId;
  int? _selectedDepAirportId;
  int? _selectedArrAirportId;
  String? _aircraftWarning;

  Future<void> _fetchAirlinesAdmin() async {
    Exception? last;
    final candidates = [
      Uri.parse('http://10.0.2.2:3000/api/admin/airlines'),
      Uri.parse('http://localhost:3000/api/admin/airlines'),
    ];
    for (final url in candidates) {
      try {
        final res = await http.get(url);
        if (res.statusCode == 200) {
          final data = json.decode(res.body) as List<dynamic>;
          setState(() {
            _airlineItems
              ..clear()
              ..addAll(data.map((e) {
                final m = e as Map<String, dynamic>;
                return AirlineItem(id: (m['airlineId'] as num).toInt(), name: (m['name'] as String?) ?? '');
              }));
            _airlines
              ..clear()
              ..addAll(_airlineItems.map((a) => a.name));
          });
          return;
        } else {
          last = Exception('HTTP ${res.statusCode}: ${res.body}');
        }
      } catch (e) {
        last = Exception('Network error: $e');
      }
    }
    if (last != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(last.toString())));
    }
  }
  Future<void> _fetchAirportsAdmin() async {
    Exception? last;
    final candidates = [
      Uri.parse('http://10.0.2.2:3000/api/admin/airports'),
      Uri.parse('http://localhost:3000/api/admin/airports'),
    ];
    for (final url in candidates) {
      try {
        final res = await http.get(url);
        print('Airports STATUS: ${res.statusCode}');
        print('Airports BODY: ${res.body}');
        if (res.statusCode == 200) {
          final decoded = json.decode(res.body);
          final List<dynamic> dataList = decoded is List
              ? decoded
              : (decoded is Map<String, dynamic> && decoded['data'] is List
                  ? decoded['data'] as List<dynamic>
                  : <dynamic>[]);
          final seen = <int>{};
          final items = <AirportItem>[];
          for (final e in dataList) {
            if (e is! Map<String, dynamic>) continue;
            try {
              final id = parseRequiredInt(e, ['airportId', 'AirportID']);
              if (seen.contains(id)) continue;
              seen.add(id);
              final name = parseString(e, ['name', 'Name']);
              final city = parseString(e, ['city', 'City']);
              final country = parseString(e, ['country', 'Country']);
              final iata = parseString(e, ['iataCode', 'IATA_Code', 'IATA']);
              items.add(AirportItem(id: id, name: name, city: city, country: country, iata: iata));
            } catch (err) {
              print('Airport parse error: $err');
              continue;
            }
          }
          setState(() {
            _airportItems
              ..clear()
              ..addAll(items);
            _airports
              ..clear()
              ..addAll(_airportItems.map((p) => '${p.iata} - ${p.name}'));
          });
          return;
        } else {
          last = Exception('HTTP ${res.statusCode}: ${res.body}');
        }
      } catch (e) {
        last = Exception('Network error: $e');
      }
    }
    if (last != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(last.toString())));
    }
  }
  Future<void> _fetchAircraftsByAirline(int airlineId) async {
    Exception? last;
    final candidates = [
      Uri.parse('http://10.0.2.2:3000/api/admin/aircrafts?airlineId=$airlineId'),
      Uri.parse('http://localhost:3000/api/admin/aircrafts?airlineId=$airlineId'),
    ];
    for (final url in candidates) {
      try {
        final res = await http.get(url);
        if (res.statusCode == 200) {
          final data = json.decode(res.body) as List<dynamic>;
          setState(() {
            _aircraftItems = data.map((e) {
              final m = e as Map<String, dynamic>;
              return AircraftItem(
                id: (m['aircraftId'] as num).toInt(),
                model: (m['model'] as String?) ?? '',
                capacity: (m['capacity'] as num?)?.toInt() ?? 0,
              );
            }).toList();
          });
          return;
        } else {
          last = Exception('HTTP ${res.statusCode}: ${res.body}');
        }
      } catch (e) {
        last = Exception('Network error: $e');
      }
    }
    if (last != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(last.toString())));
    }
  }
  String _normalizeStatus(String s) {
    final t = s.toLowerCase().trim();
    if (t == 'cancelled' || t == 'canceled') return 'Canceled';
    if (t == 'scheduled') return 'Scheduled';
    if (t == 'delayed') return 'Delayed';
    if (t == 'completed') return 'Completed';
    return s;
  }


  Future<void> _fetchFlights() async {
    Exception? last;
    final candidates = [
      Uri.parse('http://10.0.2.2:3000/api/admin/flights'),
      Uri.parse('http://localhost:3000/api/admin/flights'),
    ];
    for (final url in candidates) {
      try {
        final res = await http.get(url);
        if (res.statusCode == 200) {
          final data = json.decode(res.body) as List<dynamic>;
          setState(() {
            _flights = data.map((e) => e as Map<String, dynamic>).toList();
          });
          return;
        } else {
          last = Exception('HTTP ${res.statusCode}: ${res.body}');
        }
      } catch (e) {
        last = Exception('Network error: $e');
      }
    }
    if (last != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(last.toString())));
    }
  }

  // --- FİLTRELEME ---

  List<Map<String, dynamic>> get _filteredFlights {
    return _flights.where((f) {
      final matchesSearch =
          f['departureAirport'].toString().toLowerCase().contains(
            _searchTerm.toLowerCase(),
          ) ||
          f['arrivalAirport'].toString().toLowerCase().contains(
            _searchTerm.toLowerCase(),
          ) ||
          f['airline'].toString().toLowerCase().contains(
            _searchTerm.toLowerCase(),
          );

      final matchesAirline =
          _filterAirline.isEmpty || f['airline'] == _filterAirline;

      final matchesStatus =
          _filterStatus.isEmpty || f['status'] == _filterStatus;

      return matchesSearch && matchesAirline && matchesStatus;
    }).toList();
  }

  // --- CRUD İŞLEMLERİ ---

  int parseRequiredInt(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v != null) {
        final s = v.toString();
        final n = int.tryParse(s);
        if (n != null) return n;
      }
    }
    throw FormatException("Missing required int: ${keys.join(',')}");
  }

  int? parseOptionalInt(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v != null) {
        final s = v.toString();
        final n = int.tryParse(s);
        if (n != null) return n;
      }
    }
    return null;
  }

  String parseString(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v != null) return v.toString();
    }
    return '';
  }

  Future<void> _selectDateTime(BuildContext context, bool isDeparture) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,

      initialDate: DateTime.now(),

      firstDate: DateTime(2023),

      lastDate: DateTime(2025),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,

        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          final dt = DateTime(
            pickedDate.year,

            pickedDate.month,

            pickedDate.day,

            pickedTime.hour,

            pickedTime.minute,
          );

          if (isDeparture) {
            _departureDate = dt;

            _departureDateController.text = DateFormat(
              'yyyy-MM-dd HH:mm',
            ).format(dt);
          } else {
            _arrivalDate = dt;

            _arrivalDateController.text = DateFormat(
              'yyyy-MM-dd HH:mm',
            ).format(dt);
          }
        });
      }
    }
  }

  

  Future<void> pickDateTime({
    required BuildContext context,
    required TextEditingController controller,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      controller.text = DateFormat('yyyy-MM-dd HH:mm').format(dt);
      if (identical(controller, _departureDateController)) {
        _departureDate = dt;
      } else if (identical(controller, _arrivalDateController)) {
        _arrivalDate = dt;
      }
    });
  }

  

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFlights;

    final totalPages = (filtered.length / _itemsPerPage).ceil();

    if (_currentPage >= totalPages && totalPages > 0)
      _currentPage = totalPages - 1;

    final startIndex = _currentPage * _itemsPerPage;

    final endIndex = min(startIndex + _itemsPerPage, filtered.length);

    final currentData = filtered.isEmpty
        ? []
        : filtered.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // --- HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      "Uçuş Yönetimi",

                      style: TextStyle(
                        fontSize: 24,

                        fontWeight: FontWeight.bold,

                        color: Colors.black87,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      "Tüm uçuşları görüntüleyin ve yönetin",

                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),

                
              ],
            ),

            const SizedBox(height: 24),

            // --- FİLTRELER ---
            Container(
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(12),

                border: Border.all(color: Colors.grey.shade200),
              ),

              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 800;

                  return Flex(
                    direction: isMobile ? Axis.vertical : Axis.horizontal,

                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchTerm = val),

                          decoration: const InputDecoration(
                            hintText: "Havayolu, kalkış veya varış ara...",

                            prefixIcon: Icon(Icons.search),

                            border: OutlineInputBorder(),

                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(
                        width: isMobile ? 0 : 16,

                        height: isMobile ? 16 : 0,
                      ),

                      SizedBox(
                        width: isMobile ? double.infinity : 200,

                        child: DropdownButtonFormField<String?>(
                          value: _filterAirline.isEmpty ? null : _filterAirline,

                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),

                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),

                            hintText: "Tüm Havayolları",
                          ),

                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text("Tüm Havayolları"),
                            ),
                            ..._airlines.map(
                              (a) => DropdownMenuItem<String?>(value: a, child: Text(a)),
                            ),
                          ],
 
                          onChanged: (val) =>
                              setState(() => _filterAirline = val ?? ""),
                        ),
                      ),

                      SizedBox(
                        width: isMobile ? 0 : 16,

                        height: isMobile ? 16 : 0,
                      ),

                      SizedBox(
                        width: isMobile ? double.infinity : 200,

                        child: DropdownButtonFormField<String>(
                          value: _filterStatus.isEmpty ? null : _filterStatus,

                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),

                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),

                            hintText: "Tüm Durumlar",
                          ),

                          items: [
                            const DropdownMenuItem(
                              value: "All",
                              child: Text("Tüm Durumlar"),
                            ),
                            ..._statuses.map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            ),
                          ],
 
                          onChanged: (val) => setState(() {
                            _filterStatus = (val == null || val == 'All') ? "" : val;
                          }),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // --- KART LİSTESİ ---
            if (currentData.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),

                  child: Text("Uçuş bulunamadı."),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 1100
                      ? 3
                      : (constraints.maxWidth > 700 ? 2 : 1);

                  return GridView.builder(
                    shrinkWrap: true,

                    physics: const NeverScrollableScrollPhysics(),

                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,

                      crossAxisSpacing: 16,

                      mainAxisSpacing: 16,

                      childAspectRatio: 1.4, // Kart oranı
                    ),

                    itemCount: currentData.length,

                    itemBuilder: (context, index) {
                      return _FlightCard(
                        flight: currentData[index],
                      );
                    },
                  );
                },
              ),

            // --- SAYFALAMA ---
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                IconButton(
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,

                  icon: const Icon(Icons.chevron_left),
                ),

                Text("Sayfa ${_currentPage + 1} / $totalPages"),

                IconButton(
                  onPressed: _currentPage < totalPages - 1
                      ? () => setState(() => _currentPage++)
                      : null,

                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- UÇUŞ KARTI ---

class _FlightCard extends StatelessWidget {
  final Map<String, dynamic> flight;

  const _FlightCard({
    required this.flight,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Scheduled':
        return Colors.blue;

      case 'Delayed':
        return Colors.orange;

      case 'Canceled':
        return Colors.red;

      case 'Completed':
        return Colors.green;

      case 'Boarding':
        return Colors.purple;

      case 'Departed':
        return Colors.teal;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(flight['status']);

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: Colors.grey.shade200),

        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      flight['airline'],

                      style: const TextStyle(
                        fontWeight: FontWeight.bold,

                        fontSize: 15,
                      ),

                      overflow: TextOverflow.ellipsis,
                    ),

                    Text(
                      flight['aircraft'],

                      style: TextStyle(
                        fontSize: 12,

                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Flight ID: ${flight['flightID']}",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),

                  borderRadius: BorderRadius.circular(8),
                ),

                child: Text(
                  flight['status'],

                  style: TextStyle(
                    fontSize: 11,

                    fontWeight: FontWeight.bold,

                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 16),

          // Kalkış
          Row(
            children: [
              const Icon(Icons.flight_takeoff, size: 16, color: Colors.teal),

              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      flight['departureAirport'],

                      style: const TextStyle(
                        fontSize: 13,

                        fontWeight: FontWeight.w500,
                      ),

                      overflow: TextOverflow.ellipsis,
                    ),

                    Text(
                      DateFormat(
                        'dd MMM HH:mm',
                      ).format(DateTime.parse(flight['departureTime'])),

                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Varış
          Row(
            children: [
              const Icon(Icons.flight_land, size: 16, color: Colors.orange),

              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      flight['arrivalAirport'],

                      style: const TextStyle(
                        fontSize: 13,

                        fontWeight: FontWeight.w500,
                      ),

                      overflow: TextOverflow.ellipsis,
                    ),

                    Text(
                      DateFormat(
                        'dd MMM HH:mm',
                      ).format(DateTime.parse(flight['arrivalTime'])),

                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),

          
        ],
      ),
    );
  }
}
