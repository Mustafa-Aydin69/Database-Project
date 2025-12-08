import 'package:flutter/material.dart';
import 'dart:math';

class VehicleTypesScreen extends StatefulWidget {
  const VehicleTypesScreen({super.key});

  @override
  State<VehicleTypesScreen> createState() => _VehicleTypesScreenState();
}

class _VehicleTypesScreenState extends State<VehicleTypesScreen> {
  // --- STATE ---
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  String _searchTerm = "";

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _typeNameController = TextEditingController();
  final TextEditingController _multiplierController = TextEditingController();

  // --- MOCK VERİLER (React'ten alındı) ---
  List<Map<String, dynamic>> _vehicleTypes = [
    {'typeID': 1, 'typeName': 'Otomobil', 'priceMultiplier': 1.0},
    {'typeID': 2, 'typeName': 'SUV', 'priceMultiplier': 1.3},
    {'typeID': 3, 'typeName': 'Minibüs', 'priceMultiplier': 1.5},
    {'typeID': 4, 'typeName': 'Motosiklet', 'priceMultiplier': 0.7},
    {'typeID': 5, 'typeName': 'Kamyonet', 'priceMultiplier': 1.8},
    // Sayfalama için veri çoğaltalım
    ...List.generate(10, (index) => {
      'typeID': 6 + index,
      'typeName': 'Özel Araç ${index + 1}',
      'priceMultiplier': 1.0 + (index * 0.1)
    }),
  ];

  // --- FİLTRELEME ---
  List<Map<String, dynamic>> get _filteredTypes {
    return _vehicleTypes.where((t) {
      return t['typeName'].toString().toLowerCase().contains(_searchTerm.toLowerCase());
    }).toList();
  }

  // --- CRUD İŞLEMLERİ ---

  void _showTypeDialog({Map<String, dynamic>? type}) {
    if (type != null) {
      _typeNameController.text = type['typeName'];
      _multiplierController.text = type['priceMultiplier'].toString();
    } else {
      _typeNameController.clear();
      _multiplierController.text = "1.0";
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(type != null ? 'Araç Tipi Düzenle' : 'Yeni Araç Tipi'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _typeNameController,
                    decoration: const InputDecoration(
                        labelText: "Araç Tipi",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.directions_car),
                        hintText: "Örn: Otomobil"
                    ),
                    validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _multiplierController,
                    decoration: const InputDecoration(
                      labelText: "Fiyat Çarpanı",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calculate),
                      helperText: "Temel ücrete uygulanacak çarpan (örn: 1.5)",
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Zorunlu alan";
                      if (double.tryParse(v) == null) return "Geçerli sayı giriniz";
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
                  if (type != null) {
                    // Güncelle
                    final index = _vehicleTypes.indexWhere((t) => t['typeID'] == type['typeID']);
                    _vehicleTypes[index] = {
                      'typeID': type['typeID'],
                      'typeName': _typeNameController.text,
                      'priceMultiplier': double.parse(_multiplierController.text),
                    };
                  } else {
                    // Ekle
                    _vehicleTypes.insert(0, {
                      'typeID': DateTime.now().millisecondsSinceEpoch,
                      'typeName': _typeNameController.text,
                      'priceMultiplier': double.parse(_multiplierController.text),
                    });
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text(type != null ? "Güncelle" : "Ekle"),
          ),
        ],
      ),
    );
  }

  void _deleteType(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Bu araç tipini silmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          TextButton(
            onPressed: () {
              setState(() => _vehicleTypes.removeWhere((t) => t['typeID'] == id));
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
    final filtered = _filteredTypes;
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
                    Text("Araç Tipleri", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text("Araç sınıflarını ve fiyat çarpanlarını yönetin", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showTypeDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Yeni Araç Tipi"),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- ARAMA ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: TextField(
                onChanged: (val) => setState(() => _searchTerm = val),
                decoration: const InputDecoration(
                  hintText: "Araç tipi ara...",
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- KART LİSTESİ ---
            if (currentData.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Araç tipi bulunamadı.")))
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  // Araç Tipi kartları küçük olduğu için 3-4 sütun olabilir
                  int crossAxisCount = constraints.maxWidth > 1100 ? 4 : (constraints.maxWidth > 700 ? 2 : 1);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.8, // Kart boyutu
                    ),
                    itemCount: currentData.length,
                    itemBuilder: (context, index) {
                      return _VehicleTypeCard(
                        type: currentData[index],
                        onEdit: () => _showTypeDialog(type: currentData[index]),
                        onDelete: () => _deleteType(currentData[index]['typeID']),
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

// --- ARAÇ TİPİ KARTI ---
class _VehicleTypeCard extends StatelessWidget {
  final Map<String, dynamic> type;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VehicleTypeCard({required this.type, required this.onEdit, required this.onDelete});

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  type['typeName'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(4)),
                child: Text("ID: ${type['typeID']}", style: TextStyle(fontSize: 11, color: Colors.teal.shade700)),
              ),
            ],
          ),

          const Divider(height: 16),

          Row(
            children: [
              const Icon(Icons.price_change, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                  "Çarpan: x${type['priceMultiplier']}",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)
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