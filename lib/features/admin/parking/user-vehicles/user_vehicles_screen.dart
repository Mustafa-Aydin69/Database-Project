import 'package:flutter/material.dart';
import 'dart:math';
import '../../../../core/services/admin_service.dart';
import '../../../../core/services/auth_service.dart';

class UserVehiclesScreen extends StatefulWidget {
  const UserVehiclesScreen({super.key});

  @override
  State<UserVehiclesScreen> createState() => _UserVehiclesScreenState();
}

class _UserVehiclesScreenState extends State<UserVehiclesScreen> {
  // --- STATE ---
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<UserVehicle> _vehicles = [];
  List<VehicleType> _vehicleTypesList = [];
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  String _searchTerm = "";
  String _filterType = "";

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  int? _selectedUserId;
  int? _selectedTypeId;
  final TextEditingController _plateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Tüm verileri yükle (araçlar + araç tipleri)
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _adminService.getUserVehicles(),
        _adminService.getVehicleTypes(),
      ]);

      setState(() {
        _vehicles = results[0] as List<UserVehicle>;
        _vehicleTypesList = results[1] as List<VehicleType>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// API'den kullanıcı araçlarını yükle (sadece araçlar için - liste yenileme)
  Future<void> _loadUserVehicles() async {
    try {
      final vehicles = await _adminService.getUserVehicles();
      setState(() {
        _vehicles = vehicles;
      });
    } catch (e) {
      debugPrint('❌ Error loading user vehicles: $e');
    }
  }

  // Araç tiplerini unique olarak al (filtreleme için - isimlerden)
  List<String> get _vehicleTypes {
    final typeSet = <String>{};
    for (var vehicle in _vehicles) {
      if (vehicle.typeName != null && vehicle.typeName!.isNotEmpty) {
        typeSet.add(vehicle.typeName!);
      }
    }
    return typeSet.toList()..sort();
  }

  // Kullanıcıları unique olarak al (modal dropdown için)
  List<Map<String, dynamic>> get _users {
    final userMap = <int, Map<String, dynamic>>{};
    for (var vehicle in _vehicles) {
      if (vehicle.userId != null && vehicle.userName != null) {
        if (!userMap.containsKey(vehicle.userId)) {
          userMap[vehicle.userId!] = {
            'id': vehicle.userId!,
            'name': vehicle.userName!,
            'email': vehicle.userEmail ?? '',
          };
        }
      }
    }
    return userMap.values.toList()..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  }

  // --- FİLTRELEME ---
  List<UserVehicle> get _filteredVehicles {
    return _vehicles.where((v) {
      final matchesSearch = (v.userName?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false) ||
          (v.plateNumber?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false);
      final matchesType = _filterType.isEmpty || v.typeName == _filterType;
      return matchesSearch && matchesType;
    }).toList();
  }

  // --- CRUD İŞLEMLERİ ---

  void _showVehicleDialog({UserVehicle? vehicle}) {
    final bool isEditing = vehicle != null;

    if (isEditing) {
      // isEditing true ise vehicle null değil
      final userVehicle = vehicle;
      _selectedUserId = userVehicle.userId;
      _selectedTypeId = userVehicle.typeId;
      _plateController.text = userVehicle.plateNumber ?? '';
    } else {
      _selectedUserId = null;
      _selectedTypeId = null;
      _plateController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(isEditing ? 'Araç Düzenle' : 'Yeni Araç'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Kullanıcı dropdown
                      DropdownButtonFormField<int>(
                        value: _selectedUserId,
                        decoration: const InputDecoration(
                          labelText: "Kullanıcı",
                          border: OutlineInputBorder(),
                        ),
                        items: _users.map((u) {
                          return DropdownMenuItem<int>(
                            value: u['id'] as int,
                            child: Text(
                              "${u['name']} (${u['email']})",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            _selectedUserId = val;
                          });
                        },
                        validator: (v) => v == null ? "Kullanıcı seçiniz" : null,
                        isExpanded: true,
                      ),
                      const SizedBox(height: 16),
                      // Araç tipi dropdown
                      DropdownButtonFormField<int>(
                        value: _selectedTypeId,
                        decoration: const InputDecoration(
                          labelText: "Araç Tipi",
                          border: OutlineInputBorder(),
                        ),
                        items: _vehicleTypesList.map((vt) {
                          return DropdownMenuItem<int>(
                            value: vt.typeId,
                            child: Text(
                              vt.typeName ?? '',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            _selectedTypeId = val;
                          });
                        },
                        validator: (v) => v == null ? "Araç tipi seçiniz" : null,
                        isExpanded: true,
                      ),
                      const SizedBox(height: 16),
                      // Plaka numarası
                      TextFormField(
                        controller: _plateController,
                        decoration: const InputDecoration(
                          labelText: "Plaka",
                          border: OutlineInputBorder(),
                          hintText: "Örn: 34 ABC 123",
                        ),
                        validator: (v) => v!.trim().isEmpty ? "Plaka numarası zorunludur" : null,
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
              if (isEditing)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
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

                      if (_selectedUserId == null || _selectedTypeId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Kullanıcı ve araç tipi seçilmelidir"),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (_plateController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Plaka numarası boş olamaz"),
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
                        final userVehicle = vehicle; // isEditing true ise vehicle null değil
                        if (userVehicle.vehicleId == null) {
                          if (mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Araç ID bulunamadı"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        final success = await _adminService.updateUserVehicle(
                          vehicleId: userVehicle.vehicleId!,
                          userId: _selectedUserId!,
                          typeId: _selectedTypeId!,
                          plateNumber: _plateController.text.trim(),
                          logUserId: userId,
                        );

                        // Loading dialog'u kapat
                        if (mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }

                        if (success) {
                          // Modal'ı kapat
                          Navigator.pop(context);
                          
                          // Başarılı mesajı göster
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Araç başarıyla güncellendi"),
                              backgroundColor: Colors.green,
                            ),
                          );
                          
                          // Listeyi yenile
                          _loadUserVehicles();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Araç güncellenirken bir hata oluştu"),
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
                  },
                  child: const Text("Güncelle"),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
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

                      if (_selectedUserId == null || _selectedTypeId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Kullanıcı ve araç tipi seçilmelidir"),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (_plateController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Plaka numarası boş olamaz"),
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
                        final result = await _adminService.addUserVehicle(
                          userId: _selectedUserId!,
                          typeId: _selectedTypeId!,
                          plateNumber: _plateController.text.trim(),
                          logUserId: userId,
                        );

                        // Loading dialog'u kapat
                        if (mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }

                        if (result['success'] == true) {
                          // Modal'ı kapat
                          Navigator.pop(context);
                          
                          // Başarılı mesajı göster
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Araç başarıyla eklendi"),
                              backgroundColor: Colors.green,
                            ),
                          );
                          
                          // Listeyi yenile
                          _loadUserVehicles();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? "Araç eklenirken bir hata oluştu"),
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
                  },
                  child: const Text("Ekle"),
                ),
            ],
          );
        },
      ),
    );
  }

  void _deleteVehicle(int id) async {
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

    // Onay modalı göster
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text(
          "Bu aracı silmek istediğinizden emin misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return; // Kullanıcı iptal etti
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
      final success = await _adminService.deleteUserVehicle(
        vehicleId: id,
        logUserId: userId,
      );

      // Loading dialog'u kapat
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (success) {
        // Başarılı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Araç başarıyla silindi"),
            backgroundColor: Colors.green,
          ),
        );
        // Listeyi yenile
        _loadUserVehicles();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Araç silinirken bir hata oluştu"),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
                            ..._vehicleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))),
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
                        onDelete: () => _deleteVehicle(currentData[index].vehicleId ?? 0),
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
  final UserVehicle vehicle;
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
                    Text(vehicle.userName ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                    Text(vehicle.userEmail ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(vehicle.typeName ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
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
                child: Text(vehicle.plateNumber ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
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