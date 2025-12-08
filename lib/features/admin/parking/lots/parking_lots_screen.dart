import 'package:flutter/material.dart';
import 'dart:math';

class ParkingLotsScreen extends StatefulWidget {
  const ParkingLotsScreen({super.key});

  @override
  State<ParkingLotsScreen> createState() => _ParkingLotsScreenState();
}

class _ParkingLotsScreenState extends State<ParkingLotsScreen> {
  // --- STATE ---
  int _currentPage = 0;
  final int _itemsPerPage = 8; // Kartlar biraz büyük olabilir, 8 tane yeterli
  String _searchTerm = "";
  String _filterAirport = "";

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  String? _selectedAirport;
  final TextEditingController _lotNameController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // Sabit Listeler
  final List<String> _airports = [
    'İstanbul Havalimanı (IST)',
    'Sabiha Gökçen (SAW)',
    'Antalya Havalimanı (AYT)',
    'Esenboğa (ESB)'
  ];

  // --- MOCK VERİLER (React'ten alındı) ---
  List<Map<String, dynamic>> _parkingLots = [
    {'parkingLotID': 1, 'airportName': 'İstanbul Havalimanı (IST)', 'lotName': 'A Terminali Otopark', 'capacity': 500, 'locationDescription': 'Terminal A yanı, kısa süreli park', 'occupiedSpots': 342},
    {'parkingLotID': 2, 'airportName': 'İstanbul Havalimanı (IST)', 'lotName': 'B Terminali Otopark', 'capacity': 450, 'locationDescription': 'Terminal B yanı, uzun süreli park', 'occupiedSpots': 289},
    {'parkingLotID': 3, 'airportName': 'Sabiha Gökçen (SAW)', 'lotName': 'Açık Otopark', 'capacity': 300, 'locationDescription': 'Terminal karşısı, ekonomik park', 'occupiedSpots': 156},
    {'parkingLotID': 4, 'airportName': 'Antalya Havalimanı (AYT)', 'lotName': 'Kapalı Otopark', 'capacity': 600, 'locationDescription': 'Terminal altı, kapalı alan', 'occupiedSpots': 478},
    // Sayfalama için veri üretelim
    ...List.generate(10, (index) => {
      'parkingLotID': 5 + index,
      'airportName': index % 2 == 0 ? 'Esenboğa (ESB)' : 'Sabiha Gökçen (SAW)',
      'lotName': 'Otopark ${index + 1}',
      'capacity': 200 + (index * 50),
      'locationDescription': 'Bölge ${index + 1}',
      'occupiedSpots': (50 + index * 10) // Rastgele doluluk
    }),
  ];

  // --- FİLTRELEME ---
  List<Map<String, dynamic>> get _filteredLots {
    return _parkingLots.where((lot) {
      final matchesSearch = lot['lotName'].toString().toLowerCase().contains(_searchTerm.toLowerCase()) ||
          lot['locationDescription'].toString().toLowerCase().contains(_searchTerm.toLowerCase());
      final matchesFilter = _filterAirport.isEmpty || lot['airportName'] == _filterAirport;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  // --- CRUD İŞLEMLERİ ---

  void _showLotDialog({Map<String, dynamic>? lot}) {
    if (lot != null) {
      _selectedAirport = lot['airportName'];
      _lotNameController.text = lot['lotName'];
      _capacityController.text = lot['capacity'].toString();
      _locationController.text = lot['locationDescription'];
    } else {
      _selectedAirport = null;
      _lotNameController.clear();
      _capacityController.text = "100";
      _locationController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(lot != null ? 'Otopark Düzenle' : 'Yeni Otopark'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedAirport,
                    decoration: const InputDecoration(labelText: "Havalimanı", border: OutlineInputBorder()),
                    items: _airports.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                    onChanged: (val) => setState(() => _selectedAirport = val),
                    validator: (v) => v == null ? "Seçiniz" : null,
                    isExpanded: true,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lotNameController,
                    decoration: const InputDecoration(labelText: "Otopark Adı", border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _capacityController,
                    decoration: const InputDecoration(labelText: "Kapasite", border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || int.tryParse(v) == null) ? "Geçerli sayı giriniz" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: "Konum Açıklaması", border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  if (lot != null) {
                    final index = _parkingLots.indexWhere((l) => l['parkingLotID'] == lot['parkingLotID']);
                    _parkingLots[index] = {
                      ..._parkingLots[index],
                      'airportName': _selectedAirport,
                      'lotName': _lotNameController.text,
                      'capacity': int.parse(_capacityController.text),
                      'locationDescription': _locationController.text,
                    };
                  } else {
                    _parkingLots.insert(0, {
                      'parkingLotID': DateTime.now().millisecondsSinceEpoch,
                      'airportName': _selectedAirport,
                      'lotName': _lotNameController.text,
                      'capacity': int.parse(_capacityController.text),
                      'locationDescription': _locationController.text,
                      'occupiedSpots': 0, // Yeni otopark boş başlar
                    });
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text(lot != null ? "Güncelle" : "Ekle"),
          ),
        ],
      ),
    );
  }

  void _deleteLot(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Bu otopark alanını silmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          TextButton(
            onPressed: () {
              setState(() => _parkingLots.removeWhere((l) => l['parkingLotID'] == id));
              Navigator.pop(context);
            },
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sayfalama
    final filtered = _filteredLots;
    final totalPages = (filtered.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = min(startIndex + _itemsPerPage, filtered.length);
    final currentData = filtered.isEmpty ? [] : filtered.sublist(startIndex, endIndex);

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
                    Text("Otopark Alanları", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text("Havalimanlarına bağlı otopark alanlarını yönetin", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showLotDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Yeni Otopark"),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- FİLTRELER ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 600;
                  return Flex(
                    direction: isMobile ? Axis.vertical : Axis.horizontal,
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchTerm = val),
                          decoration: const InputDecoration(
                            hintText: "Otopark ara...",
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
                      SizedBox(
                        width: isMobile ? double.infinity : 300,
                        child: DropdownButtonFormField<String>(
                          value: _filterAirport.isEmpty ? null : _filterAirport,
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12), hintText: "Tüm Havalimanları"),
                          items: [
                            const DropdownMenuItem(value: "", child: Text("Tüm Havalimanları")),
                            ..._airports.map((a) => DropdownMenuItem(value: a, child: Text(a))),
                          ],
                          onChanged: (val) => setState(() => _filterAirport = val ?? ""),
                          isExpanded: true,
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
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Otopark bulunamadı.")))
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  // Otopark kartları biraz büyük, 2-3 sütun ideal
                  int crossAxisCount = constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5, // Kart boyutu
                    ),
                    itemCount: currentData.length,
                    itemBuilder: (context, index) {
                      return _ParkingLotCard(
                        lot: currentData[index],
                        onEdit: () => _showLotDialog(lot: currentData[index]),
                        onDelete: () => _deleteLot(currentData[index]['parkingLotID']),
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
                IconButton(onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null, icon: const Icon(Icons.chevron_left)),
                Text("Sayfa ${_currentPage + 1} / $totalPages"),
                IconButton(onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null, icon: const Icon(Icons.chevron_right)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- OTOPARK KARTI ---
class _ParkingLotCard extends StatelessWidget {
  final Map<String, dynamic> lot;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ParkingLotCard({required this.lot, required this.onEdit, required this.onDelete});

  Color _getOccupancyColor(double percentage) {
    if (percentage >= 0.9) return Colors.red;
    if (percentage >= 0.7) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final double percentage = lot['occupiedSpots'] / lot['capacity'];
    final Color progressColor = _getOccupancyColor(percentage);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
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
                    Text(lot['lotName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                    Text(lot['airportName'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text("#${lot['parkingLotID']}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
              ),
            ],
          ),

          const Divider(height: 16),

          Row(
            children: [
              const Icon(Icons.map, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(child: Text(lot['locationDescription'], style: TextStyle(fontSize: 13, color: Colors.grey.shade700), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 12),

          // Doluluk Barı
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Doluluk", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    "${lot['occupiedSpots']}/${lot['capacity']} (%${(percentage * 100).toInt()})",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: progressColor),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 8,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(onTap: onEdit, child: const Icon(Icons.edit, size: 20, color: Colors.teal)),
              const SizedBox(width: 16),
              InkWell(onTap: onDelete, child: const Icon(Icons.delete_outline, size: 20, color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }
}