import 'package:flutter/material.dart';
import 'dart:math';
import '../../../../core/services/admin_service.dart';

class VehicleTypesScreen extends StatefulWidget {
  const VehicleTypesScreen({super.key});

  @override
  State<VehicleTypesScreen> createState() => _VehicleTypesScreenState();
}

class _VehicleTypesScreenState extends State<VehicleTypesScreen> {
  // --- STATE ---
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<VehicleType> _vehicleTypes = [];
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  String _searchTerm = "";

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _typeNameController = TextEditingController();
  final TextEditingController _multiplierController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVehicleTypes();
  }

  /// API'den araç tiplerini yükle
  Future<void> _loadVehicleTypes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final vehicleTypes = await _adminService.getVehicleTypes();
      setState(() {
        _vehicleTypes = vehicleTypes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading vehicle types: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- FİLTRELEME ---
  List<VehicleType> get _filteredTypes {
    return _vehicleTypes.where((t) {
      return (t.typeName?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false);
    }).toList();
  }

  // --- CRUD İŞLEMLERİ ---

  void _showTypeDialog({VehicleType? type}) {
    // Düzenleme modunda olup olmadığımızı kontrol eden değişken
    final bool isEditing = type != null;

    if (isEditing) {
      final vehicleType = type!; // isEditing true ise type null değil
      _typeNameController.text = vehicleType.typeName ?? '';
      _multiplierController.text = vehicleType.priceMultiplier?.toString() ?? '1.0';
    } else {
      _typeNameController.clear();
      _multiplierController.text = "1.0";
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEditing ? 'Araç Tipi Düzenle' : 'Yeni Araç Tipi'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- ARAÇ TİPİ (DÜZENLEME MODUNDA KİLİTLİ) ---
                  TextFormField(
                    controller: _typeNameController,
                    // Düzenleme modunda değiştirilemez (disabled)
                    enabled: !isEditing,
                    decoration: InputDecoration(
                      labelText: "Araç Tipi",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.directions_car),
                      hintText: "Örn: Otomobil",
                      // Kilitli olduğunu hissettirmek için gri arka plan ekleyelim
                      filled: isEditing,
                      fillColor: isEditing ? Colors.grey.shade200 : null,
                    ),
                    validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // --- FİYAT ÇARPANI (HER ZAMAN DÜZENLENEBİLİR) ---
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
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // TODO: Güncelleme/Ekleme işlemleri backend'e eklendiğinde burada yapılacak
                // Şimdilik sadece dialog'u kapatıyoruz
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEditing 
                        ? "Araç tipi güncelleme işlemi yakında aktif olacak" 
                        : "Yeni araç tipi ekleme işlemi yakında aktif olacak"),
                    backgroundColor: Colors.orange,
                  ),
                );
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
  final VehicleType type;
  final VoidCallback onEdit;

  const _VehicleTypeCard({required this.type, required this.onEdit});

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
                  type.typeName ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(4)),
                child: Text("ID: ${type.typeId ?? 'N/A'}", style: TextStyle(fontSize: 11, color: Colors.teal.shade700)),
              ),
            ],
          ),

          const Divider(height: 16),

          Row(
            children: [
              const Icon(Icons.price_change, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                  "Çarpan: x${type.priceMultiplier ?? 'N/A'}",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)
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