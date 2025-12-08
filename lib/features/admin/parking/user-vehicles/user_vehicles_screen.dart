import 'package:flutter/material.dart';
import 'dart:math';

class UserVehiclesScreen extends StatefulWidget {
  const UserVehiclesScreen({super.key});

  @override
  State<UserVehiclesScreen> createState() => _UserVehiclesScreenState();
}

class _UserVehiclesScreenState extends State<UserVehiclesScreen> {
  // --- STATE ---
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  String _searchTerm = "";
  String _filterType = "";

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  int? _selectedUserId;
  int? _selectedTypeId;
  final TextEditingController _plateController = TextEditingController();

  // Sabit Listeler
  final List<Map<String, dynamic>> _users = [
    {'id': 1, 'name': 'Ahmet Yılmaz', 'email': 'ahmet.yilmaz@email.com'},
    {'id': 2, 'name': 'Mehmet Kaya', 'email': 'mehmet.kaya@email.com'},
    {'id': 3, 'name': 'Ayşe Demir', 'email': 'ayse.demir@email.com'},
  ];

  final List<Map<String, dynamic>> _vehicleTypes = [
    {'id': 1, 'name': 'Otomobil'},
    {'id': 2, 'name': 'SUV'},
    {'id': 3, 'name': 'Minibüs'},
    {'id': 4, 'name': 'Motosiklet'},
    {'id': 5, 'name': 'Kamyonet'},
  ];

  // --- MOCK VERİLER (React'ten alındı) ---
  List<Map<String, dynamic>> _vehicles = [
    {'vehicleID': 1, 'userID': 1, 'userName': 'Ahmet Yılmaz', 'userEmail': 'ahmet.yilmaz@email.com', 'typeID': 1, 'typeName': 'Otomobil', 'plateNumber': '34 ABC 123'},
    {'vehicleID': 2, 'userID': 2, 'userName': 'Mehmet Kaya', 'userEmail': 'mehmet.kaya@email.com', 'typeID': 2, 'typeName': 'SUV', 'plateNumber': '06 XYZ 456'},
    {'vehicleID': 3, 'userID': 1, 'userName': 'Ahmet Yılmaz', 'userEmail': 'ahmet.yilmaz@email.com', 'typeID': 4, 'typeName': 'Motosiklet', 'plateNumber': '34 MN 789'},
    {'vehicleID': 4, 'userID': 3, 'userName': 'Ayşe Demir', 'userEmail': 'ayse.demir@email.com', 'typeID': 3, 'typeName': 'Minibüs', 'plateNumber': '35 DEF 321'},
    // Sayfalama için veri üretelim
    ...List.generate(15, (index) => {
      'vehicleID': 5 + index,
      'userID': (index % 3) + 1,
      'userName': 'User ${index + 1}',
      'userEmail': 'user${index + 1}@email.com',
      'typeID': (index % 5) + 1,
      'typeName': 'Type ${index + 1}',
      'plateNumber': '34 TES ${100 + index}'
    }),
  ];

  // --- FİLTRELEME ---
  List<Map<String, dynamic>> get _filteredVehicles {
    return _vehicles.where((v) {
      final matchesSearch = v['userName'].toString().toLowerCase().contains(_searchTerm.toLowerCase()) ||
          v['plateNumber'].toString().toLowerCase().contains(_searchTerm.toLowerCase());
      final matchesType = _filterType.isEmpty || v['typeName'] == _filterType;
      return matchesSearch && matchesType;
    }).toList();
  }

  // --- CRUD İŞLEMLERİ ---

  void _showVehicleDialog({Map<String, dynamic>? vehicle}) {
    if (vehicle != null) {
      _selectedUserId = vehicle['userID'];
      _selectedTypeId = vehicle['typeID'];
      _plateController.text = vehicle['plateNumber'];
    } else {
      _selectedUserId = null;
      _selectedTypeId = null;
      _plateController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(vehicle != null ? 'Araç Düzenle' : 'Yeni Araç'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: _selectedUserId,
                    decoration: const InputDecoration(labelText: "Kullanıcı", border: OutlineInputBorder()),
                    items: _users.map((u) => DropdownMenuItem(value: u['id'] as int, child: Text("${u['name']} (${u['email']})", overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) => setState(() => _selectedUserId = val),
                    validator: (v) => v == null ? "Seçiniz" : null,
                    isExpanded: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedTypeId,
                    decoration: const InputDecoration(labelText: "Araç Tipi", border: OutlineInputBorder()),
                    items: _vehicleTypes.map((t) => DropdownMenuItem(value: t['id'] as int, child: Text(t['name']))).toList(),
                    onChanged: (val) => setState(() => _selectedTypeId = val),
                    validator: (v) => v == null ? "Seçiniz" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _plateController,
                    decoration: const InputDecoration(labelText: "Plaka", border: OutlineInputBorder(), hintText: "Örn: 34 ABC 123"),
                    validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
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
                  final user = _users.firstWhere((u) => u['id'] == _selectedUserId);
                  final type = _vehicleTypes.firstWhere((t) => t['id'] == _selectedTypeId);

                  if (vehicle != null) {
                    final index = _vehicles.indexWhere((v) => v['vehicleID'] == vehicle['vehicleID']);
                    _vehicles[index] = {
                      'vehicleID': vehicle['vehicleID'],
                      'userID': _selectedUserId,
                      'userName': user['name'],
                      'userEmail': user['email'],
                      'typeID': _selectedTypeId,
                      'typeName': type['name'],
                      'plateNumber': _plateController.text,
                    };
                  } else {
                    _vehicles.insert(0, {
                      'vehicleID': DateTime.now().millisecondsSinceEpoch,
                      'userID': _selectedUserId,
                      'userName': user['name'],
                      'userEmail': user['email'],
                      'typeID': _selectedTypeId,
                      'typeName': type['name'],
                      'plateNumber': _plateController.text,
                    });
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text(vehicle != null ? "Güncelle" : "Ekle"),
          ),
        ],
      ),
    );
  }

  void _deleteVehicle(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Bu aracı silmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          TextButton(
            onPressed: () {
              setState(() => _vehicles.removeWhere((v) => v['vehicleID'] == id));
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
    final filtered = _filteredVehicles;
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
                    Text("Kullanıcı Araçları", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text("Kullanıcıların sisteme kayıtlı araçlarını yönetin", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showVehicleDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Yeni Araç"),
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
                            hintText: "Kullanıcı veya plaka ara...",
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
                      SizedBox(
                        width: isMobile ? double.infinity : 250,
                        child: DropdownButtonFormField<String>(
                          value: _filterType.isEmpty ? null : _filterType,
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12), hintText: "Tüm Araç Tipleri"),
                          items: [
                            const DropdownMenuItem(value: "", child: Text("Tüm Araç Tipleri")),
                            ..._vehicleTypes.map((t) => DropdownMenuItem(value: t['name'] as String, child: Text(t['name'] as String))),
                          ],
                          onChanged: (val) => setState(() => _filterType = val ?? ""),
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
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Araç bulunamadı.")))
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
                      childAspectRatio: 1.8,
                    ),
                    itemCount: currentData.length,
                    itemBuilder: (context, index) {
                      return _UserVehicleCard(
                        vehicle: currentData[index],
                        onEdit: () => _showVehicleDialog(vehicle: currentData[index]),
                        onDelete: () => _deleteVehicle(currentData[index]['vehicleID']),
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

// --- KULLANICI ARACI KARTI ---
class _UserVehicleCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserVehicleCard({required this.vehicle, required this.onEdit, required this.onDelete});

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle['userName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                    Text(vehicle['userEmail'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(vehicle['typeName'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
              ),
            ],
          ),

          const Divider(height: 16),

          Row(
            children: [
              const Icon(Icons.confirmation_number, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                child: Text(vehicle['plateNumber'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
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