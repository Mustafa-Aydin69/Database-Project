import 'package:flutter/material.dart';
import 'dart:math';

class ParkingSpotsScreen extends StatefulWidget {
  const ParkingSpotsScreen({super.key});

  @override
  State<ParkingSpotsScreen> createState() => _ParkingSpotsScreenState();
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
  final TextEditingController _spotNumberController = TextEditingController();
  bool _isReserved = false;

  // Sabit Listeler (Otoparklar)
  final List<String> _parkingLots = [
    'A Terminali Otopark',
    'B Terminali Otopark',
    'Açık Otopark',
    'Kapalı Otopark'
  ];

  // --- MOCK VERİLER (React'ten alındı) ---
  List<Map<String, dynamic>> _spots = [
    {'spotID': 1, 'parkingLotName': 'A Terminali Otopark', 'spotNumber': 'A-001', 'isReserved': true},
    {'spotID': 2, 'parkingLotName': 'A Terminali Otopark', 'spotNumber': 'A-002', 'isReserved': false},
    {'spotID': 3, 'parkingLotName': 'A Terminali Otopark', 'spotNumber': 'A-003', 'isReserved': true},
    {'spotID': 4, 'parkingLotName': 'B Terminali Otopark', 'spotNumber': 'B-001', 'isReserved': false},
    {'spotID': 5, 'parkingLotName': 'B Terminali Otopark', 'spotNumber': 'B-002', 'isReserved': true},
    {'spotID': 6, 'parkingLotName': 'Açık Otopark', 'spotNumber': 'C-001', 'isReserved': false},
    // Sayfalama için veri üretelim
    ...List.generate(20, (index) => {
      'spotID': 7 + index,
      'parkingLotName': index % 2 == 0 ? 'Kapalı Otopark' : 'Açık Otopark',
      'spotNumber': 'D-${100 + index}',
      'isReserved': index % 3 == 0 // 3'te 1'i rezerve
    }),
  ];

  // --- FİLTRELEME ---
  List<Map<String, dynamic>> get _filteredSpots {
    return _spots.where((s) {
      final matchesSearch = s['spotNumber'].toString().toLowerCase().contains(_searchTerm.toLowerCase());
      final matchesLot = _filterLot.isEmpty || s['parkingLotName'] == _filterLot;

      bool matchesStatus = true;
      if (_filterStatus == 'available') matchesStatus = !s['isReserved'];
      if (_filterStatus == 'reserved') matchesStatus = s['isReserved'];

      return matchesSearch && matchesLot && matchesStatus;
    }).toList();
  }

  // --- CRUD İŞLEMLERİ ---

  void _showSpotDialog({Map<String, dynamic>? spot}) {
    if (spot != null) {
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
      builder: (context) => StatefulBuilder( // Checkbox state'i için StatefulBuilder gerekli
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(spot != null ? 'Park Yeri Düzenle' : 'Yeni Park Yeri'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedLot,
                          decoration: const InputDecoration(labelText: "Otopark", border: OutlineInputBorder()),
                          items: _parkingLots.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                          onChanged: (val) => setModalState(() => _selectedLot = val),
                          validator: (v) => v == null ? "Seçiniz" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _spotNumberController,
                          decoration: const InputDecoration(labelText: "Park Yeri No", border: OutlineInputBorder(), hintText: "Örn: A-001"),
                          validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          title: const Text("Rezerve mi?"),
                          value: _isReserved,
                          onChanged: (val) => setModalState(() => _isReserved = val ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
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
                        if (spot != null) {
                          final index = _spots.indexWhere((s) => s['spotID'] == spot['spotID']);
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
          }
      ),
    );
  }

  void _deleteSpot(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Bu park yerini silmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
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
                    Text("Park Yerleri", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text("Otopark alanlarındaki bireysel park yerlerini yönetin", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showSpotDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
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
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
                      SizedBox(
                        width: isMobile ? double.infinity : 250,
                        child: DropdownButtonFormField<String>(
                          value: _filterLot.isEmpty ? null : _filterLot,
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12), hintText: "Tüm Otoparklar"),
                          items: [
                            const DropdownMenuItem(value: "", child: Text("Tüm Otoparklar")),
                            ..._parkingLots.map((l) => DropdownMenuItem(value: l, child: Text(l))),
                          ],
                          onChanged: (val) => setState(() => _filterLot = val ?? ""),
                        ),
                      ),
                      SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
                      SizedBox(
                        width: isMobile ? double.infinity : 200,
                        child: DropdownButtonFormField<String>(
                          value: _filterStatus.isEmpty ? null : _filterStatus,
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12), hintText: "Tüm Durumlar"),
                          items: const [
                            DropdownMenuItem(value: "", child: Text("Tüm Durumlar")),
                            DropdownMenuItem(value: "available", child: Text("Müsait")),
                            DropdownMenuItem(value: "reserved", child: Text("Rezerve")),
                          ],
                          onChanged: (val) => setState(() => _filterStatus = val ?? ""),
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
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Park yeri bulunamadı.")))
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  // Park yeri kartları çok küçük, 4-5 sütun olabilir
                  int crossAxisCount = constraints.maxWidth > 1100 ? 4 : (constraints.maxWidth > 700 ? 3 : 2);
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
                        onDelete: () => _deleteSpot(currentData[index]['spotID']),
                        onToggleStatus: () => _toggleStatus(currentData[index]['spotID']),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
              ),
              InkWell(
                onTap: onToggleStatus,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                ),
              ),
            ],
          ),

          const Divider(height: 12),

          Row(
            children: [
              const Icon(Icons.local_parking, size: 16, color: Colors.blue),
              const SizedBox(width: 6),
              Expanded(child: Text(spot['parkingLotName'], style: TextStyle(fontSize: 12, color: Colors.grey.shade700), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(onTap: onEdit, child: const Icon(Icons.edit, size: 18, color: Colors.teal)),
              const SizedBox(width: 12),
              InkWell(onTap: onDelete, child: const Icon(Icons.delete_outline, size: 18, color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }
}