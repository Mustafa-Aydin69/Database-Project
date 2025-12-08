import 'package:flutter/material.dart';
import 'dart:math';

class AircraftsScreen extends StatefulWidget {
  const AircraftsScreen({super.key});

  @override
  State<AircraftsScreen> createState() => _AircraftsScreenState();
}

class _AircraftsScreenState extends State<AircraftsScreen> {
  // --- STATE ---
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  String? _selectedAirline;
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();

  // Sabit Havayolları Listesi
  final List<String> _airlineOptions = ['Turkish Airlines', 'Pegasus Airlines', 'SunExpress', 'AnadoluJet', 'Lufthansa'];

  // --- MOCK VERİLER (React'ten alındı) ---
  List<Map<String, dynamic>> _aircrafts = [
    {'id': 1, 'airlineName': 'Turkish Airlines', 'model': 'Boeing 777-300ER', 'capacity': 349},
    {'id': 2, 'airlineName': 'Turkish Airlines', 'model': 'Airbus A350-900', 'capacity': 325},
    {'id': 3, 'airlineName': 'Pegasus Airlines', 'model': 'Boeing 737-800', 'capacity': 189},
    {'id': 4, 'airlineName': 'SunExpress', 'model': 'Boeing 737 MAX 8', 'capacity': 190},
    {'id': 5, 'airlineName': 'AnadoluJet', 'model': 'Boeing 737-800', 'capacity': 189},
    // Sayfalamayı test etmek için veri çoğaltalım
    ...List.generate(15, (index) => {
      'id': 6 + index,
      'airlineName': index % 2 == 0 ? 'Lufthansa' : 'Turkish Airlines',
      'model': 'Airbus A320neo',
      'capacity': 180 + (index * 2)
    }),
  ];

  // --- CRUD İŞLEMLERİ ---

  void _showAircraftDialog({Map<String, dynamic>? aircraft}) {
    if (aircraft != null) {
      _selectedAirline = aircraft['airlineName'];
      _modelController.text = aircraft['model'];
      _capacityController.text = aircraft['capacity'].toString();
    } else {
      _selectedAirline = null;
      _modelController.clear();
      _capacityController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(aircraft != null ? 'Uçak Düzenle' : 'Yeni Uçak'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedAirline,
                    decoration: const InputDecoration(
                      labelText: "Havayolu",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.airlines),
                    ),
                    items: _airlineOptions.map((airline) {
                      return DropdownMenuItem(value: airline, child: Text(airline));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedAirline = val),
                    validator: (v) => v == null ? "Lütfen bir havayolu seçin" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: "Model",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flight),
                      hintText: "örn: Boeing 737-800",
                    ),
                    validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _capacityController,
                    decoration: const InputDecoration(
                      labelText: "Kapasite",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Zorunlu alan";
                      final cap = int.tryParse(v);
                      if (cap == null || cap <= 0) return "Kapasite 0'dan büyük olmalı";
                      return null;
                    },
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
                  if (aircraft != null) {
                    // Güncelle
                    final index = _aircrafts.indexWhere((a) => a['id'] == aircraft['id']);
                    _aircrafts[index] = {
                      'id': aircraft['id'],
                      'airlineName': _selectedAirline,
                      'model': _modelController.text,
                      'capacity': int.parse(_capacityController.text),
                    };
                  } else {
                    // Ekle
                    _aircrafts.insert(0, {
                      'id': DateTime.now().millisecondsSinceEpoch,
                      'airlineName': _selectedAirline,
                      'model': _modelController.text,
                      'capacity': int.parse(_capacityController.text),
                    });
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text(aircraft != null ? "Güncelle" : "Ekle"),
          ),
        ],
      ),
    );
  }

  void _deleteAircraft(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Bu uçağı silmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          TextButton(
            onPressed: () {
              setState(() {
                _aircrafts.removeWhere((a) => a['id'] == id);
              });
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
    final totalPages = (_aircrafts.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = min(startIndex + _itemsPerPage, _aircrafts.length);
    final currentData = _aircrafts.isEmpty ? [] : _aircrafts.sublist(startIndex, endIndex);

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
                    Text("Uçak Yönetimi", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text("Uçakları yönetin", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAircraftDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Yeni Uçak"),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- KART LİSTESİ (GRID) ---
            if (currentData.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Kayıt bulunamadı.")))
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.0, // Kart boyutu
                    ),
                    itemCount: currentData.length,
                    itemBuilder: (context, index) {
                      return _AircraftCard(
                        aircraft: currentData[index],
                        onEdit: () => _showAircraftDialog(aircraft: currentData[index]),
                        onDelete: () => _deleteAircraft(currentData[index]['id']),
                      );
                    },
                  );
                },
              ),

            const SizedBox(height: 24),

            // --- SAYFALAMA ---
            if (totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text("Sayfa ${_currentPage + 1} / $totalPages"),
                  ),
                  IconButton(
                    onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
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

// --- UÇAK KARTI ---
class _AircraftCard extends StatelessWidget {
  final Map<String, dynamic> aircraft;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AircraftCard({required this.aircraft, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
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
          // Üst Kısım
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aircraft['model'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      aircraft['airlineName'],
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(4)),
                child: Text("ID: ${aircraft['id']}", style: TextStyle(fontSize: 11, color: Colors.teal.shade700)),
              ),
            ],
          ),

          const Divider(height: 16),

          // Kapasite Bilgisi
          Row(
            children: [
              const Icon(Icons.event_seat, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text("${aircraft['capacity']} Kişi Kapasiteli", style: const TextStyle(fontSize: 13, color: Colors.black87)),
            ],
          ),

          const SizedBox(height: 8),

          // Butonlar
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 16, color: Colors.teal.shade700),
                          const SizedBox(width: 4),
                          Text("Düzenle", style: TextStyle(color: Colors.teal.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: Colors.red.shade700),
                          const SizedBox(width: 4),
                          Text("Sil", style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}