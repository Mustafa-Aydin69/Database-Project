import 'package:flutter/material.dart';
import 'dart:math';

class AirlinesScreen extends StatefulWidget {
  const AirlinesScreen({super.key});

  @override
  State<AirlinesScreen> createState() => _AirlinesScreenState();
}

class _AirlinesScreenState extends State<AirlinesScreen> {
  // --- STATE ---
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  // --- MOCK VERİLER (React'ten alındı) ---
  List<Map<String, dynamic>> _airlines = [
    {'id': 1, 'name': 'Turkish Airlines', 'country': 'Türkiye', 'contact': '+90 212 444 0 849'},
    {'id': 2, 'name': 'Pegasus Airlines', 'country': 'Türkiye', 'contact': '+90 888 228 1212'},
    {'id': 3, 'name': 'SunExpress', 'country': 'Türkiye', 'contact': '+90 444 0 797'},
    {'id': 4, 'name': 'AnadoluJet', 'country': 'Türkiye', 'contact': '+90 444 2 538'},
    {'id': 5, 'name': 'Lufthansa', 'country': 'Almanya', 'contact': '+49 69 86 799 799'},
    // Sayfalamayı test etmek için veri çoğaltalım
    ...List.generate(15, (index) => {
      'id': 6 + index,
      'name': 'Airline ${index + 1}',
      'country': index % 2 == 0 ? 'USA' : 'France',
      'contact': '+1 555 010 ${1000 + index}'
    }),
  ];

  // --- CRUD İŞLEMLERİ ---

  void _showAirlineDialog({Map<String, dynamic>? airline}) {
    if (airline != null) {
      _nameController.text = airline['name'];
      _countryController.text = airline['country'];
      _contactController.text = airline['contact'];
    } else {
      _nameController.clear();
      _countryController.clear();
      _contactController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(airline != null ? 'Havayolu Düzenle' : 'Yeni Havayolu'),
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
                      labelText: "Havayolu Adı",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flight),
                    ),
                    validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _countryController,
                    decoration: const InputDecoration(
                      labelText: "Ülke",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.public),
                    ),
                    validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactController,
                    decoration: const InputDecoration(
                      labelText: "İletişim",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
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
                  if (airline != null) {
                    // Güncelle
                    final index = _airlines.indexWhere((a) => a['id'] == airline['id']);
                    _airlines[index] = {
                      'id': airline['id'],
                      'name': _nameController.text,
                      'country': _countryController.text,
                      'contact': _contactController.text,
                    };
                  } else {
                    // Ekle
                    _airlines.insert(0, {
                      'id': DateTime.now().millisecondsSinceEpoch,
                      'name': _nameController.text,
                      'country': _countryController.text,
                      'contact': _contactController.text,
                    });
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text(airline != null ? "Güncelle" : "Ekle"),
          ),
        ],
      ),
    );
  }

  void _deleteAirline(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Bu havayolunu silmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          TextButton(
            onPressed: () {
              setState(() {
                _airlines.removeWhere((a) => a['id'] == id);
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
    final totalPages = (_airlines.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = min(startIndex + _itemsPerPage, _airlines.length);
    final currentData = _airlines.isEmpty ? [] : _airlines.sublist(startIndex, endIndex);

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
                    Text("Havayolu Yönetimi", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text("Havayolu şirketlerini yönetin", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAirlineDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Yeni Havayolu"),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- KART LİSTESİ (Responsive Grid) ---
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
                      childAspectRatio: 1.8, // Kart Oranı
                    ),
                    itemCount: currentData.length,
                    itemBuilder: (context, index) {
                      return _AirlineCard(
                        airline: currentData[index],
                        onEdit: () => _showAirlineDialog(airline: currentData[index]),
                        onDelete: () => _deleteAirline(currentData[index]['id']),
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

// --- HAVAYOLU KARTI ---
class _AirlineCard extends StatelessWidget {
  final Map<String, dynamic> airline;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AirlineCard({required this.airline, required this.onEdit, required this.onDelete});

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
          // Başlık
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  airline['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(4)),
                child: Text("ID: ${airline['id']}", style: TextStyle(fontSize: 11, color: Colors.teal.shade700)),
              ),
            ],
          ),

          const Divider(height: 24),

          // Bilgiler
          _InfoRow(icon: Icons.public, text: airline['country']),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.phone, text: airline['contact']),

          const Divider(height: 24),

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
        Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
      ],
    );
  }
}