import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para birimi formatı için
import 'dart:math';

class FlightPricingScreen extends StatefulWidget {
  const FlightPricingScreen({super.key});

  @override
  State<FlightPricingScreen> createState() => _FlightPricingScreenState();
}

class _FlightPricingScreenState extends State<FlightPricingScreen> {
  // --- STATE ---
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  String _searchTerm = "";
  String _filterClass = "";

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  String? _selectedFlight;
  String? _selectedClass;
  final TextEditingController _priceController = TextEditingController();

  // Sabit Listeler
  final List<String> _flightOptions = [
    'TK101 - IST → AYT',
    'PC202 - SAW → ADB',
    'TK303 - IST → JFK',
    'AJ404 - ESB → TZX',
  ];
  final List<String> _classOptions = ['Economy', 'Business', 'First Class'];

  // --- MOCK VERİLER (React'ten alındı) ---
  List<Map<String, dynamic>> _prices = [
    {'priceID': 1, 'flight': 'TK101 - IST → AYT', 'flightClass': 'Economy', 'price': 850.0},
    {'priceID': 2, 'flight': 'TK101 - IST → AYT', 'flightClass': 'Business', 'price': 2100.0},
    {'priceID': 3, 'flight': 'PC202 - SAW → ADB', 'flightClass': 'Economy', 'price': 650.0},
    {'priceID': 4, 'flight': 'TK303 - IST → JFK', 'flightClass': 'Economy', 'price': 8500.0},
    {'priceID': 5, 'flight': 'TK303 - IST → JFK', 'flightClass': 'Business', 'price': 18000.0},
    {'priceID': 6, 'flight': 'TK303 - IST → JFK', 'flightClass': 'First Class', 'price': 32000.0},
    // Sayfalama için ek veri
    ...List.generate(15, (index) => {
      'priceID': 7 + index,
      'flight': index % 2 == 0 ? 'TK101 - IST → AYT' : 'PC202 - SAW → ADB',
      'flightClass': index % 3 == 0 ? 'Economy' : 'Business',
      'price': 1000.0 + (index * 100)
    }),
  ];

  // --- FİLTRELEME ---
  List<Map<String, dynamic>> get _filteredPrices {
    return _prices.where((p) {
      final matchesSearch = p['flight'].toString().toLowerCase().contains(_searchTerm.toLowerCase());
      final matchesClass = _filterClass.isEmpty || p['flightClass'] == _filterClass;
      return matchesSearch && matchesClass;
    }).toList();
  }

  // --- CRUD İŞLEMLERİ ---

  void _showPriceDialog({Map<String, dynamic>? priceData}) {
    if (priceData != null) {
      _selectedFlight = priceData['flight'];
      _selectedClass = priceData['flightClass'];
      _priceController.text = priceData['price'].toString();
    } else {
      _selectedFlight = null;
      _selectedClass = null;
      _priceController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(priceData != null ? 'Fiyat Düzenle' : 'Yeni Fiyat'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedFlight,
                    decoration: const InputDecoration(
                      labelText: "Uçuş",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flight),
                    ),
                    items: _flightOptions.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                    onChanged: (val) => setState(() => _selectedFlight = val),
                    validator: (v) => v == null ? "Seçiniz" : null,
                    isExpanded: true, // Uzun metinler taşmasın
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedClass,
                    decoration: const InputDecoration(
                      labelText: "Sınıf",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.class_),
                    ),
                    items: _classOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => _selectedClass = val),
                    validator: (v) => v == null ? "Seçiniz" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: "Fiyat (₺)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Zorunlu alan";
                      if (double.tryParse(v) == null) return "Geçerli bir sayı giriniz";
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  if (priceData != null) {
                    final index = _prices.indexWhere((p) => p['priceID'] == priceData['priceID']);
                    _prices[index] = {
                      'priceID': priceData['priceID'],
                      'flight': _selectedFlight,
                      'flightClass': _selectedClass,
                      'price': double.parse(_priceController.text),
                    };
                  } else {
                    _prices.insert(0, {
                      'priceID': DateTime.now().millisecondsSinceEpoch,
                      'flight': _selectedFlight,
                      'flightClass': _selectedClass,
                      'price': double.parse(_priceController.text),
                    });
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text(priceData != null ? "Güncelle" : "Ekle"),
          ),
        ],
      ),
    );
  }

  void _deletePrice(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Bu fiyatı silmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          TextButton(
            onPressed: () {
              setState(() => _prices.removeWhere((p) => p['priceID'] == id));
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
    final filtered = _filteredPrices;
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
                    Text("Uçuş Fiyatlandırma", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text("Uçuş sınıflarına göre fiyat yönetimi", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showPriceDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Yeni Fiyat"),
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
                            hintText: "Uçuş ara...",
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
                      SizedBox(
                        width: isMobile ? double.infinity : 200,
                        child: DropdownButtonFormField<String>(
                          value: _filterClass.isEmpty ? null : _filterClass,
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12), hintText: "Tüm Sınıflar"),
                          items: [
                            const DropdownMenuItem(value: "", child: Text("Tüm Sınıflar")),
                            ..._classOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                          ],
                          onChanged: (val) => setState(() => _filterClass = val ?? ""),
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
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Fiyat bulunamadı.")))
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
                      childAspectRatio: 2.2, // Kart oranı
                    ),
                    itemCount: currentData.length,
                    itemBuilder: (context, index) {
                      return _PriceCard(
                        priceData: currentData[index],
                        onEdit: () => _showPriceDialog(priceData: currentData[index]),
                        onDelete: () => _deletePrice(currentData[index]['priceID']),
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

// --- FİYAT KARTI ---
class _PriceCard extends StatelessWidget {
  final Map<String, dynamic> priceData;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PriceCard({required this.priceData, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    // Para formatlayıcı (Örn: 1.250 ₺)
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

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
                child: Text(
                  priceData['flight'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  priceData['flightClass'],
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                ),
              ),
            ],
          ),

          const Divider(height: 20),

          Center(
            child: Text(
              currencyFormat.format(priceData['price']),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
          ),

          const Divider(height: 20),

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