import 'package:flutter/material.dart';
import 'dart:math';
import '../../../../core/services/admin_service.dart';
import '../../../../core/services/auth_service.dart';

class ParkingLotsScreen extends StatefulWidget {
  const ParkingLotsScreen({super.key});

  @override
  State<ParkingLotsScreen> createState() => _ParkingLotsScreenState();
}

class _ParkingLotsScreenState extends State<ParkingLotsScreen> {
  // --- STATE ---
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<ParkingLot> _parkingLots = [];
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

  @override
  void initState() {
    super.initState();
    _loadParkingLots();
  }

  /// API'den otopark alanlarını yükle
  Future<void> _loadParkingLots() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final parkingLots = await _adminService.getParkingLots();
      setState(() {
        _parkingLots = parkingLots;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading parking lots: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Havalimanları listesini otoparklardan çıkar (dinamik)
  List<String> get _airports {
    final airportSet = <String>{};
    for (var lot in _parkingLots) {
      if (lot.airportName != null && lot.airportName!.isNotEmpty) {
        airportSet.add(lot.airportName!);
      }
    }
    return airportSet.toList()..sort();
  }

  // Havalimanı adından AirportID'yi bul (parking lots listesinden)
  int? _getAirportIdByName(String? airportName) {
    if (airportName == null || airportName.isEmpty) return null;
    
    for (var lot in _parkingLots) {
      if (lot.airportName == airportName && lot.airportId != null) {
        return lot.airportId;
      }
    }
    return null;
  }

  // --- FİLTRELEME ---
  List<ParkingLot> get _filteredLots {
    return _parkingLots.where((lot) {
      final matchesSearch = (lot.lotName?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false) ||
          (lot.locationDescription?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false);
      final matchesFilter = _filterAirport.isEmpty || lot.airportName == _filterAirport;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  // --- CRUD İŞLEMLERİ ---

  void _showLotDialog({ParkingLot? lot}) {
    // Düzenleme modunda olup olmadığımızı kontrol eden değişken
    final bool isEditing = lot != null;

    if (isEditing) {
      final parkingLot = lot; // isEditing true ise lot null değil
      _selectedAirport = parkingLot.airportName;
      _lotNameController.text = parkingLot.lotName ?? '';
      _capacityController.text = parkingLot.capacity?.toString() ?? '0';
      _locationController.text = parkingLot.locationDescription ?? '';
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
        title: Text(isEditing ? 'Otopark Düzenle' : 'Yeni Otopark'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- HAVALİMANI (DÜZENLEME MODUNDA KİLİTLİ) ---
                  DropdownButtonFormField<String>(
                    value: _selectedAirport,
                    decoration: InputDecoration(
                      labelText: "Havalimanı",
                      border: const OutlineInputBorder(),
                      filled: isEditing,
                      fillColor: isEditing ? Colors.grey.shade200 : null,
                    ),
                    items: _airports.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                    onChanged: isEditing ? null : (val) => setState(() => _selectedAirport = val),
                    validator: (v) => v == null ? "Seçiniz" : null,
                    isExpanded: true,
                  ),
                  const SizedBox(height: 16),
                  // --- OTOPARK ADI (DÜZENLEME MODUNDA KİLİTLİ) ---
                  TextFormField(
                    controller: _lotNameController,
                    enabled: !isEditing, // Düzenleme modunda değiştirilemez (disabled)
                    decoration: InputDecoration(
                      labelText: "Otopark Adı",
                      border: const OutlineInputBorder(),
                      filled: isEditing,
                      fillColor: isEditing ? Colors.grey.shade200 : null,
                    ),
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
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                if (isEditing) {
                  // Güncelleme işlemi
                  final userId = AuthService().currentUserId;
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Kullanıcı kimliği bulunamadı. Lütfen tekrar giriş yapın."),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final parkingLot = lot; // isEditing true ise lot null değil
                  final capacity = int.tryParse(_capacityController.text.trim());
                  
                  if (capacity == null || capacity <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Geçerli bir kapasite giriniz (0'dan büyük olmalı)"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Loading dialog göster
                  if (mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (loadingContext) => const Center(child: CircularProgressIndicator()),
                    );
                  }

                  try {
                    final success = await _adminService.updateParkingLot(
                      parkingLotId: parkingLot.parkingLotId!,
                      capacity: capacity,
                      locationDescription: _locationController.text.trim().isEmpty 
                          ? null 
                          : _locationController.text.trim(),
                      userId: userId,
                    );

                    // Loading dialog'u kapat
                    if (mounted) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }

                    if (success) {
                      // Dialog'u kapat
                      Navigator.pop(context);
                      // Başarılı mesajı göster
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Otopark alanı başarıyla güncellendi"),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Listeyi yenile
                      _loadParkingLots();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Otopark alanı güncellenirken bir hata oluştu"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    // Loading dialog'u kapat
                    if (mounted) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Hata: ${e.toString()}"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  // Ekleme işlemi
                  final userId = AuthService().currentUserId;
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Kullanıcı kimliği bulunamadı. Lütfen tekrar giriş yapın."),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Seçilen havalimanı adından AirportID'yi bul
                  final airportId = _getAirportIdByName(_selectedAirport);
                  if (airportId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Havalimanı bilgisi bulunamadı. Lütfen geçerli bir havalimanı seçin."),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final capacity = int.tryParse(_capacityController.text.trim());
                  
                  if (capacity == null || capacity <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Geçerli bir kapasite giriniz (0'dan büyük olmalı)"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (_lotNameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Otopark adı boş olamaz"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Loading dialog göster
                  if (mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (loadingContext) => const Center(child: CircularProgressIndicator()),
                    );
                  }

                  try {
                    final result = await _adminService.addParkingLot(
                      airportId: airportId,
                      lotName: _lotNameController.text.trim(),
                      capacity: capacity,
                      locationDescription: _locationController.text.trim().isEmpty 
                          ? null 
                          : _locationController.text.trim(),
                      userId: userId,
                    );

                    // Loading dialog'u kapat
                    if (mounted) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }

                    if (result['success'] == true) {
                      // Dialog'u kapat
                      Navigator.pop(context);
                      // Başarılı mesajı göster
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Otopark alanı başarıyla eklendi"),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Listeyi yenile
                      _loadParkingLots();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message'] ?? 'Otopark alanı eklenirken bir hata oluştu'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    // Loading dialog'u kapat
                    if (mounted) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Hata: ${e.toString()}"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(isEditing ? "Güncelle" : "Ekle"),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
  final ParkingLot lot;
  final VoidCallback onEdit;

  const _ParkingLotCard({required this.lot, required this.onEdit});

  Color _getOccupancyColor(double percentage) {
    if (percentage >= 0.9) return Colors.red;
    if (percentage >= 0.7) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final capacity = lot.capacity ?? 1; // Sıfıra bölme hatasını önlemek için
    final occupied = lot.occupiedSpots ?? 0;
    final double percentage = capacity > 0 ? occupied / capacity : 0.0;
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
                    Text(lot.lotName ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                    Text(lot.airportName ?? 'N/A', style: TextStyle(fontSize: 12, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text("#${lot.parkingLotId ?? 'N/A'}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
              ),
            ],
          ),

          const Divider(height: 16),

          Row(
            children: [
              const Icon(Icons.map, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(child: Text(lot.locationDescription ?? 'N/A', style: TextStyle(fontSize: 13, color: Colors.grey.shade700), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
                    "$occupied/$capacity (%${(percentage * 100).toInt()})",
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
            ],
          ),
        ],
      ),
    );
  }
}