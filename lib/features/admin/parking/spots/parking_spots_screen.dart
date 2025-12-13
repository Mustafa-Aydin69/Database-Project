import 'package:flutter/material.dart';
import 'dart:math';

class ParkingSpotsScreen extends StatefulWidget {
  const ParkingSpotsScreen({super.key});

  @override
  State<ParkingSpotsScreen> createState() => _ParkingSpotsScreenState();
}

class Airport {
  final int id;
  final String name;
  final String city;
  final String iata;

  Airport({
    required this.id,
    required this.name,
    required this.city,
    required this.iata,
  });

  @override
  String toString() => "$iata - $name";
}

class _ParkingSpotsScreenState extends State<ParkingSpotsScreen> {
  // --- STATE ---
  int _currentPage = 0;
  final int _itemsPerPage = 12; // Kartlar küçük, sayfada çok gösterebiliriz
  String _searchTerm = "";
  String _filterLot = "";
  String _filterStatus = ""; // "", "available", "reserved"

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  String? _selectedLot;
  Airport? _selectedAirport;

  final TextEditingController _spotNumberController = TextEditingController();
  bool _isReserved = false;

  // Sabit Listeler (Otoparklar)
  final List<String> _parkingLots = [
    'A Terminali Otopark',
    'B Terminali Otopark',
    'Açık Otopark',
    'Kapalı Otopark',
  ];
  //Sabit Havalimanları
  final List<Airport> airports = [
    Airport(id: 1, name: "İstanbul Havalimanı", city: "İstanbul", iata: "IST"),
    Airport(
      id: 2,
      name: "Sabiha Gökçen Havalimanı",
      city: "İstanbul",
      iata: "SAW",
    ),
    Airport(id: 3, name: "Esenboğa Havalimanı", city: "Ankara", iata: "ESB"),
    Airport(
      id: 4,
      name: "İzmir Adnan Menderes Havalimanı",
      city: "İzmir",
      iata: "ADB",
    ),
    Airport(id: 5, name: "Milas-Bodrum Havalimanı", city: "Muğla", iata: "BJV"),
    Airport(id: 6, name: "Dalaman Havalimanı", city: "Muğla", iata: "DLM"),
    Airport(
      id: 7,
      name: "Denizli Çardak Havalimanı",
      city: "Denizli",
      iata: "DNZ",
    ),
    Airport(id: 8, name: "Uşak Havalimanı", city: "Uşak", iata: "USQ"),
    Airport(id: 9, name: "Zafer Havalimanı", city: "Kütahya", iata: "KZR"),
    Airport(id: 10, name: "Antalya Havalimanı", city: "Antalya", iata: "AYT"),
    Airport(
      id: 11,
      name: "Gazipaşa-Alanya Havalimanı",
      city: "Antalya",
      iata: "GZP",
    ),
    Airport(
      id: 12,
      name: "Çukurova Uluslararası Havalimanı",
      city: "Mersin",
      iata: "COV",
    ),
    Airport(id: 13, name: "Kayseri Havalimanı", city: "Kayseri", iata: "ASR"),
    Airport(id: 14, name: "Konya Havalimanı", city: "Konya", iata: "KYA"),
    Airport(
      id: 15,
      name: "Nevşehir Kapadokya Havalimanı",
      city: "Nevşehir",
      iata: "NAV",
    ),
    Airport(
      id: 16,
      name: "Sivas Nuri Demirağ Havalimanı",
      city: "Sivas",
      iata: "VAS",
    ),
    Airport(id: 17, name: "Trabzon Havalimanı", city: "Trabzon", iata: "TZX"),
    Airport(
      id: 18,
      name: "Samsun Çarşamba Havalimanı",
      city: "Samsun",
      iata: "SZF",
    ),
    Airport(id: 19, name: "Ordu-Giresun Havalimanı", city: "Ordu", iata: "OGU"),
    Airport(id: 20, name: "Rize-Artvin Havalimanı", city: "Rize", iata: "RZV"),
    Airport(id: 21, name: "Sinop Havalimanı", city: "Sinop", iata: "NOP"),
    Airport(
      id: 22,
      name: "Kastamonu Havalimanı",
      city: "Kastamonu",
      iata: "KFS",
    ),
    Airport(id: 23, name: "Erzurum Havalimanı", city: "Erzurum", iata: "ERZ"),
    Airport(
      id: 24,
      name: "Van Ferit Melen Havalimanı",
      city: "Van",
      iata: "VAN",
    ),
    Airport(
      id: 25,
      name: "Malatya Erhaç Havalimanı",
      city: "Malatya",
      iata: "MLX",
    ),
    Airport(id: 26, name: "Elazığ Havalimanı", city: "Elazığ", iata: "EZS"),
    Airport(
      id: 27,
      name: "Muş Sultan Alparslan Havalimanı",
      city: "Muş",
      iata: "MSR",
    ),
    Airport(
      id: 28,
      name: "Kars Harakani Havalimanı",
      city: "Kars",
      iata: "KSY",
    ),
    Airport(
      id: 29,
      name: "Ağrı Ahmed-i Hani Havalimanı",
      city: "Ağrı",
      iata: "AJI",
    ),
    Airport(
      id: 30,
      name: "Gaziantep Havalimanı",
      city: "Gaziantep",
      iata: "GZT",
    ),
    Airport(
      id: 31,
      name: "Şanlıurfa GAP Havalimanı",
      city: "Şanlıurfa",
      iata: "GNY",
    ),
    Airport(
      id: 32,
      name: "Diyarbakır Havalimanı",
      city: "Diyarbakır",
      iata: "DIY",
    ),
    Airport(id: 33, name: "Batman Havalimanı", city: "Batman", iata: "BAL"),
    Airport(
      id: 34,
      name: "Mardin Prof. Dr. Aziz Sancar Havalimanı",
      city: "Mardin",
      iata: "MQM",
    ),
    Airport(id: 35, name: "Siirt Havalimanı", city: "Siirt", iata: "SXZ"),
  ];

  // --- MOCK VERİLER (React'ten alındı) ---
  List<Map<String, dynamic>> _spots = [
    {
      'spotID': 1,
      'airportName': 'IST - İstanbul Havalimanı',
      'parkingLotName': 'A Terminali Otopark',
      'spotNumber': 'A-001',
      'isReserved': true,
    },
    {
      'spotID': 2,
      'airportName': 'IST - İstanbul Havalimanı',
      'parkingLotName': 'A Terminali Otopark',
      'spotNumber': 'A-002',
      'isReserved': false,
    },
    {
      'spotID': 3,
      'airportName': 'SAW - Sabiha Gökçen',
      'parkingLotName': 'B Terminali Otopark',
      'spotNumber': 'B-001',
      'isReserved': false,
    },
    // Sayfalama için veri üretelim
    ...List.generate(
      10,
      (index) => {
        'spotID': 4 + index,
        'airportName': index % 2 == 0
            ? 'SAW - Sabiha Gökçen'
            : 'IST - İstanbul Havalimanı',
        'parkingLotName': 'Otopark ${index + 1}',
        'spotNumber': 'C-${100 + index}',
        'isReserved': index % 2 == 0 ? false : true,
      },
    ),
  ];

  // --- FİLTRELEME ---
  List<Map<String, dynamic>> get _filteredSpots {
    return _spots.where((s) {
      final matchesSearch = s['spotNumber'].toString().toLowerCase().contains(
        _searchTerm.toLowerCase(),
      );
      final matchesLot =
          _filterLot.isEmpty || s['parkingLotName'] == _filterLot;

      bool matchesStatus = true;
      if (_filterStatus == 'available') matchesStatus = !s['isReserved'];
      if (_filterStatus == 'reserved') matchesStatus = s['isReserved'];

      return matchesSearch && matchesLot && matchesStatus;
    }).toList();
  }

  // --- CRUD İŞLEMLERİ ---

  void _showSpotDialog({Map<String, dynamic>? spot}) {
    if (spot != null) {
      final int? airportId = spot['airportId'] as int?;
      _selectedAirport = airportId == null
          ? null
          : airports.firstWhere((a) => a.id == airportId);
      _selectedLot = spot['parkingLotName'];
      _spotNumberController.text = spot['spotNumber'];
      _isReserved = spot['isReserved'];
    } else {
      _selectedLot = null;
      _spotNumberController.clear();
      _isReserved = false;
    }
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        // Checkbox state'i için StatefulBuilder gerekli
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(spot != null ? 'Park Yeri Düzenle' : 'Yeni Park Yeri'),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<Airport>(
                        value: _selectedAirport,
                        decoration: const InputDecoration(
                          labelText: "Havalimanı",
                          border: OutlineInputBorder(),
                        ),
                        items: airports.map((airport) {
                          return DropdownMenuItem<Airport>(
                            value: airport,
                            child: Text("${airport.iata} - ${airport.name}"),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setModalState(() => _selectedAirport = val),
                        validator: (v) =>
                            v == null ? "Havalimanı seçiniz" : null,
                      ),

                      DropdownButtonFormField<String>(
                        value: _selectedLot,
                        decoration: const InputDecoration(
                          labelText: "Otopark",
                          border: OutlineInputBorder(),
                        ),
                        items: _parkingLots
                            .map(
                              (l) => DropdownMenuItem(value: l, child: Text(l)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setModalState(() => _selectedLot = val),
                        validator: (v) => v == null ? "Seçiniz" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _spotNumberController,
                        decoration: const InputDecoration(
                          labelText: "Park Yeri No",
                          border: OutlineInputBorder(),
                          hintText: "Örn: A-001",
                        ),
                        validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text("Rezerve mi?"),
                        value: _isReserved,
                        onChanged: (val) =>
                            setModalState(() => _isReserved = val ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      if (spot != null) {
                        final index = _spots.indexWhere(
                          (s) => s['spotID'] == spot['spotID'],
                        );
                        _spots[index] = {
                          'spotID': spot['spotID'],
                          'parkingLotName': _selectedLot,
                          'spotNumber': _spotNumberController.text,
                          'isReserved': _isReserved,
                        };
                      } else {
                        _spots.insert(0, {
                          'spotID': DateTime.now().millisecondsSinceEpoch,
                          'parkingLotName': _selectedLot,
                          'spotNumber': _spotNumberController.text,
                          'isReserved': _isReserved,
                        });
                      }
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text(spot != null ? "Güncelle" : "Ekle"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteSpot(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text(
          "Bu park yerini silmek istediğinizden emin misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () {
              setState(() => _spots.removeWhere((s) => s['spotID'] == id));
              Navigator.pop(context);
            },
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleStatus(int id) {
    setState(() {
      final index = _spots.indexWhere((s) => s['spotID'] == id);
      if (index != -1) {
        _spots[index]['isReserved'] = !_spots[index]['isReserved'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSpots;
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
                      "Park Yerleri",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Otopark alanlarındaki bireysel park yerlerini yönetin",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showSpotDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Yeni Park Yeri"),
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
                            hintText: "Park yeri ara...",
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
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
                        width: isMobile ? double.infinity : 250,
                        child: DropdownButtonFormField<String>(
                          value: _filterLot.isEmpty ? null : _filterLot,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            hintText: "Tüm Otoparklar",
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: "",
                              child: Text("Tüm Otoparklar"),
                            ),
                            ..._parkingLots.map(
                              (l) => DropdownMenuItem(value: l, child: Text(l)),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _filterLot = val ?? ""),
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
                          items: const [
                            DropdownMenuItem(
                              value: "",
                              child: Text("Tüm Durumlar"),
                            ),
                            DropdownMenuItem(
                              value: "available",
                              child: Text("Müsait"),
                            ),
                            DropdownMenuItem(
                              value: "reserved",
                              child: Text("Rezerve"),
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
                  child: Text("Park yeri bulunamadı."),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  // Park yeri kartları çok küçük, 4-5 sütun olabilir
                  int crossAxisCount = constraints.maxWidth > 1100
                      ? 4
                      : (constraints.maxWidth > 700 ? 3 : 2);
                  // Mobilde çok küçük olmasın diye min 2
                  if (constraints.maxWidth < 500) crossAxisCount = 1;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.6,
                    ),
                    itemCount: currentData.length,
                    itemBuilder: (context, index) {
                      return _ParkingSpotCard(
                        spot: currentData[index],
                        onEdit: () => _showSpotDialog(spot: currentData[index]),
                        onDelete: () =>
                            _deleteSpot(currentData[index]['spotID']),
                        onToggleStatus: () =>
                            _toggleStatus(currentData[index]['spotID']),
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

// --- PARK YERİ KARTI ---
class _ParkingSpotCard extends StatelessWidget {
  final Map<String, dynamic> spot;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const _ParkingSpotCard({
    required this.spot,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final bool isReserved = spot['isReserved'];
    final Color statusColor = isReserved ? Colors.red : Colors.green;
    final String statusText = isReserved ? 'Rezerve' : 'Müsait';

    return Container(
      padding: const EdgeInsets.all(12),
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
              Text(
                spot['spotNumber'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              InkWell(
                onTap: onToggleStatus,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 12),

          Row(
            children: [
              const Icon(Icons.local_parking, size: 16, color: Colors.blue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  spot['parkingLotName'],
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(Icons.flight, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  spot['airportName'],
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: onEdit,
                child: const Icon(Icons.edit, size: 18, color: Colors.teal),
              ),
              const SizedBox(width: 12),
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
