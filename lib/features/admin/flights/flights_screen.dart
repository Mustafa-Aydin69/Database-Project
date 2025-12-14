import 'package:flutter/material.dart';

import 'dart:math';

import 'package:intl/intl.dart'; // Tarih formatı için

class FlightsScreen extends StatefulWidget {
  const FlightsScreen({super.key});

  @override
  State<FlightsScreen> createState() => _FlightsScreenState();
}

class _FlightsScreenState extends State<FlightsScreen> {
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

  final List<String> _airlines = [
    'Turkish Airlines',

    'Pegasus Airlines',

    'AnadoluJet',

    'SunExpress',
  ];

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

    'Cancelled',

    'Boarding',

    'Departed',

    'Arrived',
  ];

  // --- MOCK VERİLER (React'ten alındı) ---

  List<Map<String, dynamic>> _flights = [
    {
      'flightID': 1,

      'airline': 'Turkish Airlines',

      'aircraft': 'Boeing 737-800',

      'departureAirport': 'IST - İstanbul Havalimanı',

      'arrivalAirport': 'AYT - Antalya Havalimanı',

      'departureTime': '2024-01-15T10:30',

      'arrivalTime': '2024-01-15T12:00',

      'status': 'Scheduled',
    },

    {
      'flightID': 2,

      'airline': 'Pegasus Airlines',

      'aircraft': 'Airbus A320',

      'departureAirport': 'SAW - Sabiha Gökçen',

      'arrivalAirport': 'ADB - İzmir Adnan Menderes',

      'departureTime': '2024-01-15T14:00',

      'arrivalTime': '2024-01-15T15:15',

      'status': 'Delayed',
    },

    {
      'flightID': 3,

      'airline': 'Turkish Airlines',

      'aircraft': 'Boeing 777-300ER',

      'departureAirport': 'IST - İstanbul Havalimanı',

      'arrivalAirport': 'JFK - New York JFK',

      'departureTime': '2024-01-15T23:45',

      'arrivalTime': '2024-01-16T05:30',

      'status': 'Scheduled',
    },

    {
      'flightID': 4,

      'airline': 'AnadoluJet',

      'aircraft': 'Boeing 737-800',

      'departureAirport': 'ESB - Esenboğa',

      'arrivalAirport': 'TZX - Trabzon',

      'departureTime': '2024-01-15T08:00',

      'arrivalTime': '2024-01-15T09:45',

      'status': 'Cancelled',
    },

    // Sayfalama için veri üretelim
    ...List.generate(
      15,

      (index) => {
        'flightID': 5 + index,

        'airline': index % 2 == 0 ? 'Turkish Airlines' : 'Pegasus Airlines',

        'aircraft': 'Airbus A320',

        'departureAirport': 'IST - İstanbul Havalimanı',

        'arrivalAirport': 'ESB - Esenboğa',

        'departureTime': '2024-01-${16 + index}T10:00',

        'arrivalTime': '2024-01-${16 + index}T11:30',

        'status': 'Scheduled',
      },
    ),
  ];

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

  Future<void> _selectDateTime(BuildContext context, bool isDeparture) async {
    final now = DateTime.now();
    final safeInitialDate = now.isAfter(DateTime(2030, 12, 31))
        ? DateTime(2030, 12, 31)
        : now;
    
    final DateTime? pickedDate = await showDatePicker(
      context: context,

      initialDate: safeInitialDate,

      firstDate: DateTime(2023),

      lastDate: DateTime(2030, 12, 31),
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
              'dd.MM.yyyy HH:mm',
            ).format(dt);
          } else {
            _arrivalDate = dt;

            _arrivalDateController.text = DateFormat(
              'dd.MM.yyyy HH:mm',
            ).format(dt);
          }
        });
      }
    }
  }

  

  void _showFlightDialog({Map<String, dynamic>? flight}) {
    final bool isEdit = flight != null;
    if (flight != null) {
      _selectedAirline = flight['airline'];

      _selectedAircraft = flight['aircraft'];

      _selectedDepAirport = flight['departureAirport'];

      _selectedArrAirport = flight['arrivalAirport'];

      _departureDate = DateTime.parse(flight['departureTime']);

      _arrivalDate = DateTime.parse(flight['arrivalTime']);

      _selectedStatus = flight['status'];

      _departureDateController.text = DateFormat(
        'dd.MM.yyyy HH:mm',
      ).format(_departureDate!);

      _arrivalDateController.text = DateFormat(
        'dd.MM.yyyy HH:mm',
      ).format(_arrivalDate!);
    } else {
      _selectedAirline = null;

      _selectedAircraft = null;

      _selectedDepAirport = null;

      _selectedArrAirport = null;

      _departureDate = null;

      _arrivalDate = null;

      _selectedStatus = 'Scheduled';

      _departureDateController.clear();

      _arrivalDateController.clear();
    }

    showDialog(
      context: context,

      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(flight != null ? 'Uçuş Düzenle' : 'Yeni Uçuş'),

            content: SizedBox(
              width: 600, // Geniş modal

              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,

                  child: Column(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedAirline,

                              decoration: const InputDecoration(
                                labelText: "Havayolu",

                                border: OutlineInputBorder(),
                              ),

                              items: _airlines
                                  .map(
                                    (a) => DropdownMenuItem(
                                      value: a,

                                      child: Text(a),
                                    ),
                                  )
                                  .toList(),

                              onChanged: isEdit
                                  ? null
                                  : (val) => setDialogState(
                                      () => _selectedAirline = val,
                                    ),

                              validator: (v) => v == null ? "Seçiniz" : null,
                            ),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedAircraft,

                              decoration: const InputDecoration(
                                labelText: "Uçak",

                                border: OutlineInputBorder(),
                              ),

                              items: _aircrafts
                                  .map(
                                    (a) => DropdownMenuItem(
                                      value: a,

                                      child: Text(a),
                                    ),
                                  )
                                  .toList(),

                              onChanged: isEdit
                                  ? null
                                  : (val) => setDialogState(
                                      () => _selectedAircraft = val,
                                    ),

                              validator: (v) => v == null ? "Seçiniz" : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedDepAirport,

                              decoration: const InputDecoration(
                                labelText: "Kalkış Havalimanı",

                                border: OutlineInputBorder(),
                              ),

                              items: _airports
                                  .map(
                                    (a) => DropdownMenuItem(
                                      value: a,

                                      child: Text(
                                        a,

                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),

                              onChanged: isEdit
                                  ? null
                                  : (val) => setDialogState(
                                      () => _selectedDepAirport = val,
                                    ),

                              validator: (v) => v == null ? "Seçiniz" : null,

                              isExpanded: true,
                            ),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedArrAirport,

                              decoration: const InputDecoration(
                                labelText: "Varış Havalimanı",

                                border: OutlineInputBorder(),
                              ),

                              items: _airports
                                  .map(
                                    (a) => DropdownMenuItem(
                                      value: a,

                                      child: Text(
                                        a,

                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),

                              onChanged: isEdit
                                  ? null
                                  : (val) => setDialogState(
                                      () => _selectedDepAirport = val,
                                    ),

                              validator: (v) => v == null ? "Seçiniz" : null,

                              isExpanded: true,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                FocusScope.of(context).unfocus();

                                await _selectDateTime(context, true);

                                setDialogState(() {});
                              },

                              child: AbsorbPointer(
                                child: TextFormField(
                                  readOnly: true,

                                  decoration: const InputDecoration(
                                    labelText: "Kalkış Zamanı",

                                    border: OutlineInputBorder(),

                                    suffixIcon: Icon(Icons.calendar_today),
                                  ),

                                  controller: _departureDateController,

                                  validator: (v) => _departureDate == null
                                      ? "Kalkış zamanı seçiniz"
                                      : null,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                FocusScope.of(context).unfocus();

                                await _selectDateTime(context, false);

                                setDialogState(() {});
                              },

                              child: AbsorbPointer(
                                child: TextFormField(
                                  readOnly: true,

                                  decoration: const InputDecoration(
                                    labelText: "Varış Zamanı",

                                    border: OutlineInputBorder(),

                                    suffixIcon: Icon(Icons.calendar_today),
                                  ),

                                  controller: _arrivalDateController,

                                  validator: (v) => _arrivalDate == null
                                      ? "Varış zamanı seçiniz"
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _selectedStatus,

                        decoration: const InputDecoration(
                          labelText: "Durum",

                          border: OutlineInputBorder(),
                        ),

                        items: _statuses
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),

                        onChanged: (val) =>
                            setDialogState(() => _selectedStatus = val!),
                      ),
                    ],
                  ),
                ),
              ),
            ), // content kapanışı

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),

                child: const Text("İptal"),
              ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,

                  foregroundColor: Colors.white,
                ),

                onPressed: () {
                  if (_formKey.currentState!.validate() &&
                      _departureDate != null &&
                      _arrivalDate != null) {
                    setState(() {
                      if (flight != null) {
                        final index = _flights.indexWhere(
                          (f) => f['flightID'] == flight['flightID'],
                        );

                        _flights[index] = {
                          'flightID': flight['flightID'],

                          'airline': _selectedAirline,

                          'aircraft': _selectedAircraft,

                          'departureAirport': _selectedDepAirport,

                          'arrivalAirport': _selectedArrAirport,

                          'departureTime': _departureDate!.toIso8601String(),

                          'arrivalTime': _arrivalDate!.toIso8601String(),

                          'status': _selectedStatus,
                        };
                      } else {
                        _flights.insert(0, {
                          'flightID': DateTime.now().millisecondsSinceEpoch,

                          'airline': _selectedAirline,

                          'aircraft': _selectedAircraft,

                          'departureAirport': _selectedDepAirport,

                          'arrivalAirport': _selectedArrAirport,

                          'departureTime': _departureDate!.toIso8601String(),

                          'arrivalTime': _arrivalDate!.toIso8601String(),

                          'status': _selectedStatus,
                        });
                      }
                    });

                    Navigator.pop(context);
                  }
                },

                child: Text(flight != null ? "Güncelle" : "Ekle"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteFlight(int id) {
    setState(() {
      _flights.removeWhere((f) => f['flightID'] == id);
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

                ElevatedButton.icon(
                  onPressed: () => _showFlightDialog(),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,

                    foregroundColor: Colors.white,

                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,

                      vertical: 12,
                    ),
                  ),

                  icon: const Icon(Icons.add),

                  label: const Text("Yeni Uçuş"),
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

                        child: DropdownButtonFormField<String>(
                          value: _filterAirline.isEmpty ? null : _filterAirline,

                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),

                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),

                            hintText: "Tüm Havayolları",
                          ),

                          items: [
                            const DropdownMenuItem(
                              value: "",

                              child: Text("Tüm Havayolları"),
                            ),

                            ..._airlines.map(
                              (a) => DropdownMenuItem(value: a, child: Text(a)),
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
                              value: "",

                              child: Text("Tüm Durumlar"),
                            ),

                            ..._statuses.map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            ),
                          ],

                          onChanged: (val) =>
                              setState(() => _filterStatus = val ?? ""),
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

                        onEdit: () =>
                            _showFlightDialog(flight: currentData[index]),

                        onDelete: () =>
                            _deleteFlight(currentData[index]['flightID']),
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

  final VoidCallback onEdit;

  final VoidCallback onDelete;

  const _FlightCard({
    required this.flight,

    required this.onEdit,

    required this.onDelete,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Scheduled':
        return Colors.blue;

      case 'Delayed':
        return Colors.orange;

      case 'Cancelled':
        return Colors.red;

      case 'Boarding':
        return Colors.purple;

      case 'Departed':
        return Colors.teal;

      case 'Arrived':
        return Colors.green;

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

          const SizedBox(height: 8),

          Wrap(
            alignment: WrapAlignment.end,

            spacing: 12,

            children: [
              InkWell(
                onTap: onEdit,

                child: const Icon(Icons.edit, size: 18, color: Colors.teal),
              ),

              InkWell(
                onTap: onDelete,

                child: const Icon(
                  Icons.delete_outline,

                  size: 18,

                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
