import 'package:flutter/material.dart';
import 'dart:math';

class AirportsScreen extends StatefulWidget {
  const AirportsScreen({super.key});

  @override
  State<AirportsScreen> createState() => _AirportsScreenState();
}

class _AirportsScreenState extends State<AirportsScreen> {
  // --- STATE ---
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _iataController = TextEditingController();

  // --- MOCK VERİLER (React'ten alındı) ---
  List<Map<String, dynamic>> _airports = [
    {'id': 1, 'name': 'İstanbul Havalimanı', 'city': 'İstanbul', 'country': 'Türkiye', 'iataCode': 'IST'},
    {'id': 2, 'name': 'Sabiha Gökçen Havalimanı', 'city': 'İstanbul', 'country': 'Türkiye', 'iataCode': 'SAW'},
    {'id': 3, 'name': 'Esenboğa Havalimanı', 'city': 'Ankara', 'country': 'Türkiye', 'iataCode': 'ESB'},
    {'id': 4, 'name': 'Antalya Havalimanı', 'city': 'Antalya', 'country': 'Türkiye', 'iataCode': 'AYT'},
    {'id': 5, 'name': 'İzmir Adnan Menderes', 'city': 'İzmir', 'country': 'Türkiye', 'iataCode': 'ADB'},
    // Sayfalamayı test etmek için veri üretelim
    ...List.generate(15, (index) => {
      'id': 6 + index,
      'name': 'International Airport ${index + 1}',
      'city': 'City ${index + 1}',
      'country': index % 3 == 0 ? 'USA' : 'Germany',
      'iataCode': 'A${10 + index}'
    }),
  ];

  // --- CRUD İŞLEMLERİ ---

  void _showAirportDialog({Map<String, dynamic>? airport}) {
    if (airport != null) {
      _nameController.text = airport['name'];
      _cityController.text = airport['city'];
      _countryController.text = airport['country'];
      _iataController.text = airport['iataCode'];
    } else {
      _nameController.clear();
      _cityController.clear();
      _countryController.clear();
      _iataController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(airport != null ? 'Havalimanı Düzenle' : 'Yeni Havalimanı'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Havalimanı Adı",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flight_takeoff),
                    ),
                    validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: "Şehir",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_city),
                          ),
                          validator: (v) => v!.isEmpty ? "Gerekli" : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _countryController,
                          decoration: const InputDecoration(
                            labelText: "Ülke",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.public),
                          ),
                          validator: (v) => v!.isEmpty ? "Gerekli" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _iataController,
                    decoration: const InputDecoration(
                      labelText: "IATA Kodu (Örn: IST)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.tag),
                      counterText: "", // Altındaki karakter sayacını gizle
                    ),
                    maxLength: 3,
                    textCapitalization: TextCapitalization.characters, // Otomatik büyük harf
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Zorunlu alan";
                      if (value.length != 3) return "3 karakter olmalı";

                      // Benzersizlik Kontrolü
                      final isDuplicate = _airports.any((a) =>
                      a['iataCode'] == value && (airport == null || a['id'] != airport['id'])
                      );

                      if (isDuplicate) return "Bu kod zaten kullanılıyor!";
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
                  if (airport != null) {
                    // Güncelle
                    final index = _airports.indexWhere((a) => a['id'] == airport['id']);
                    _airports[index] = {
                      'id': airport['id'],
                      'name': _nameController.text,
                      'city': _cityController.text,
                      'country': _countryController.text,
                      'iataCode': _iataController.text.toUpperCase(),
                    };
                  } else {
                    // Ekle
                    _airports.insert(0, {
                      'id': DateTime.now().millisecondsSinceEpoch,
                      'name': _nameController.text,
                      'city': _cityController.text,
                      'country': _countryController.text,
                      'iataCode': _iataController.text.toUpperCase(),
                    });
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text(airport != null ? "Güncelle" : "Ekle"),
          ),
        ],
      ),
    );
  }

  void _deleteAirport(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Bu havalimanını silmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          TextButton(
            onPressed: () {
              setState(() {
                _airports.removeWhere((a) => a['id'] == id);
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
    final totalPages = (_airports.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = min(startIndex + _itemsPerPage, _airports.length);
    final currentData = _airports.isEmpty ? [] : _airports.sublist(startIndex, endIndex);

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
                    Text("Havalimanı Yönetimi", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text("Havalimanlarını yönetin", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAirportDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Yeni Havalimanı"),
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
                      return _AirportCard(
                        airport: currentData[index],
                        onEdit: () => _showAirportDialog(airport: currentData[index]),
                        onDelete: () => _deleteAirport(currentData[index]['id']),
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

// --- HAVALİMANI KARTI ---
class _AirportCard extends StatelessWidget {
  final Map<String, dynamic> airport;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AirportCard({required this.airport, required this.onEdit, required this.onDelete});

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
          // Üst Kısım: İsim ve IATA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  airport['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  airport['iataCode'],
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                ),
              ),
            ],
          ),

          const Divider(height: 16),

          // Orta Kısım: Lokasyon
          _InfoRow(icon: Icons.location_city, text: "${airport['city']}, ${airport['country']}"),

          const SizedBox(height: 8),

          // Alt Kısım: Butonlar
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade700), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}