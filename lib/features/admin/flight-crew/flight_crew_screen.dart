import 'package:flutter/material.dart';
import 'dart:math';
import '../../../core/services/flight_crew_service.dart';

class FlightCrewScreen extends StatefulWidget {
  const FlightCrewScreen({super.key});

  @override
  State<FlightCrewScreen> createState() => _FlightCrewScreenState();
}

class _FlightCrewScreenState extends State<FlightCrewScreen> {
  // --- STATE ---
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  String _searchTerm = "";
  String _filterFlight = "";

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  String? _selectedFlight;
  String? _selectedEmployee;
  String? _selectedRole;

  // --- SABİT LİSTELER (Dinamik) ---
  List<Map<String, dynamic>> _availableFlights = [];
  List<Map<String, dynamic>> _availableEmployees = [];
  List<String> _availableRoles = [];
  
  // Seçilen değerlerin ID'leri
  int? _selectedFlightID;
  int? _selectedEmployeeID;
  String? _selectedRoleName;

  // --- FİLTRE LİSTELERİ ---
  List<String> _flights = [];

  // --- MOCK VERİLER ---
  List<Map<String, dynamic>> _crews = [];
  // Gruplanmış veri: employeeID -> {name, assignments: [{crewID, flight, role}]}
  List<Map<String, dynamic>> _groupedCrews = [];
  bool _loading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    
    // Paralel olarak verileri çek
    final results = await Future.wait([
      FlightCrewService().fetchCrewList(),
      FlightCrewService().fetchFlights(),
      FlightCrewService().fetchEmployees(),
      FlightCrewService().fetchRoles(),
    ]);

    final items = results[0] as List<FlightCrewItem>;
    final flights = results[1] as List<Map<String, dynamic>>;
    final employees = results[2] as List<Map<String, dynamic>>;
    final roles = results[3] as List<String>;

    // Ham liste
    final rawList = items.map((e) => {
      'crewID': e.crewID,
      'flight': e.flight,
      'employee': e.employee,
      'employeeID': e.employeeID,
      'role': e.role,
    }).toList();

    // Gruplama
    final Map<int, Map<String, dynamic>> groups = {};
    for (var item in items) {
      if (!groups.containsKey(item.employeeID)) {
        groups[item.employeeID] = {
          'employeeID': item.employeeID,
          'employee': item.employee,
          'assignments': <Map<String, dynamic>>[],
        };
      }
      groups[item.employeeID]!['assignments'].add({
        'crewID': item.crewID,
        'flight': item.flight,
        'role': item.role,
      });
    }

    setState(() {
      _crews = rawList;
      _groupedCrews = groups.values.toList();
      _availableFlights = flights;
      _availableEmployees = employees;
      _availableRoles = roles;
      
      // Filtreler için mevcut listeden de alabiliriz ama dinamik listeler daha doğru
      _flights = _crews.map((e) => e['flight'] as String).toSet().toList()..sort();
      // _employees ve _roles filtreleri de UI'da varsa güncellenebilir
      
      _loading = false;
      if (_crews.isEmpty) {
        _loadError = null;
      }
    });
  }

  // --- FİLTRELEME ---
  List<Map<String, dynamic>> get _filteredGroupedCrews {
    return _groupedCrews.where((g) {
      final assignments = g['assignments'] as List;
      final employeeName = g['employee'].toString();
      
      // Arama filtresi: Çalışan adı veya herhangi bir rolü eşleşiyor mu?
      bool matchesSearch = false;
      if (_searchTerm.isEmpty) {
        matchesSearch = true;
      } else {
        if (employeeName.toLowerCase().contains(_searchTerm.toLowerCase())) matchesSearch = true;
        // Rollerde ara
        for (var a in assignments) {
          if (a['role'].toString().toLowerCase().contains(_searchTerm.toLowerCase())) {
            matchesSearch = true;
            break;
          }
        }
      }

      // Uçuş filtresi: Herhangi bir assignment seçili uçuşta mı?
      bool matchesFlight = false;
      if (_filterFlight.isEmpty) {
        matchesFlight = true;
      } else {
        for (var a in assignments) {
          if (a['flight'] == _filterFlight) {
            matchesFlight = true;
            break;
          }
        }
      }

      return matchesSearch && matchesFlight;
    }).toList();
  }

  // --- CRUD İŞLEMLERİ ---

  void _showCrewDialog({Map<String, dynamic>? crew}) {
    // Sadece ekleme modu için id'leri sıfırla, düzenleme modu henüz desteklenmiyor (ID maplemeleri karışık olabilir)
    if (crew == null) {
      _selectedFlightID = null;
      _selectedEmployeeID = null;
      _selectedRoleName = null;
    } else {
      // Düzenleme modu şimdilik basit tutuluyor veya deaktif edilebilir
      // _selectedRoleName = crew['role'];
      // _selectedFlightID = ... (bunu bulmak zor çünkü listede sadece string var)
      // Bu yüzden sadece yeni ekleme üzerine odaklanalım.
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(crew != null ? 'Mürettebat Düzenle' : 'Yeni Mürettebat'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: _selectedFlightID,
                    decoration: const InputDecoration(
                      labelText: "Uçuş",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flight),
                    ),
                    items: _availableFlights.map((f) => DropdownMenuItem(
                      value: f['FlightID'] as int,
                      child: Text(f['Label'] ?? '', overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedFlightID = val),
                    validator: (v) => v == null ? "Seçiniz" : null,
                    isExpanded: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedEmployeeID,
                    decoration: const InputDecoration(
                      labelText: "Çalışan",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: _availableEmployees.map((e) => DropdownMenuItem(
                      value: e['EmployeeID'] as int,
                      child: Text(e['Name'] ?? ''),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedEmployeeID = val),
                    validator: (v) => v == null ? "Seçiniz" : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRoleName,
                    decoration: const InputDecoration(
                      labelText: "Rol",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                    items: _availableRoles.map((r) => DropdownMenuItem(
                      value: r, 
                      child: Text(r)
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedRoleName = val),
                    validator: (v) => v == null ? "Seçiniz" : null,
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
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                if (crew == null) {
                  // Yeni Ekleme
                  final success = await FlightCrewService().addCrew(
                    _selectedFlightID!, 
                    _selectedEmployeeID!, 
                    _selectedRoleName!
                  );
                  
                  if (success) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mürettebat eklendi")));
                      _fetchData();
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ekleme başarısız")));
                    }
                  }
                } else {
                  // Güncelleme (şimdilik pasif veya uyarı)
                  Navigator.pop(context);
                }
              }
            },
            child: Text(crew != null ? "Güncelle" : "Ekle"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCrew(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Bu çalışana ait TÜM mürettebat kayıtlarını silmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İptal")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await FlightCrewService().deleteCrewByEmployee(id);
      if (success) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kayıtlar silindi")));
           _fetchData(); // Listeyi yenile
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Silme başarısız oldu")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredGroupedCrews;
    final totalPages = (filtered.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    if (totalPages == 0) _currentPage = 0;
    
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
                    Text("Uçuş Mürettebatı", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text("Uçuş ekiplerini yönetin", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCrewDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Mürettebat Ekle"),
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
                            hintText: "Çalışan veya rol ara...",
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
                      SizedBox(
                        width: isMobile ? double.infinity : 300,
                        child: DropdownButtonFormField<String>(
                          value: _filterFlight.isEmpty ? null : _filterFlight,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12),
                              hintText: "Tüm Uçuşlar"
                          ),
                          items: [
                            const DropdownMenuItem(value: "", child: Text("Tüm Uçuşlar")),
                            ..._flights.map((f) => DropdownMenuItem(value: f, child: Text(f, overflow: TextOverflow.ellipsis))),
                          ],
                          onChanged: (val) => setState(() => _filterFlight = val ?? ""),
                          isExpanded: true,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (currentData.isEmpty)
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
                      childAspectRatio: 1.8, // Daha uzun kartlar için aspect ratio düşürüldü
                    ),
                    itemCount: currentData.length,
                    itemBuilder: (context, index) {
                      return _GroupedCrewCard(
                        group: currentData[index],
                        onEdit: (crew) => _showCrewDialog(crew: crew),
                        onDelete: (id) => _deleteCrew(id), // employeeID gönderiliyor
                      );
                    },
                  );
                },
              ),
            
            // --- SAYFALAMA ---
            const SizedBox(height: 24),
            if (totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Önceki Sayfa
                  InkWell(
                    onTap: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: _currentPage > 0 ? Colors.white : Colors.grey.shade100,
                      ),
                      child: Icon(Icons.chevron_left, color: _currentPage > 0 ? Colors.black87 : Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Sayfa Numaraları
                  ...List.generate(totalPages, (index) {
                    // Sayfa sayısı çok fazlaysa hepsini gösterme mantığı (basit: ilk 5, son 5 veya sliding window)
                    // Şimdilik 10 sayfaya kadar hepsini gösterelim, sonrası için ... eklenebilir ama user isteği "1,2,3,4" şeklinde.
                    if (totalPages > 10 && (index > 2 && index < totalPages - 3 && (index < _currentPage - 1 || index > _currentPage + 1))) {
                      if (index == 3 && _currentPage > 4) return const Text(" ... ");
                      if (index == totalPages - 4 && _currentPage < totalPages - 5) return const SizedBox(); // Tekrar ... koymamak için
                      return const SizedBox.shrink();
                    }
                    
                    final isSelected = _currentPage == index;
                    return GestureDetector(
                      onTap: () => setState(() => _currentPage = index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.teal : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? Colors.teal : Colors.grey.shade300),
                          boxShadow: isSelected ? [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : null,
                        ),
                        child: Text(
                          "${index + 1}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }).where((w) => w is! SizedBox), // Boş widget'ları temizle

                  const SizedBox(width: 12),
                  
                  // Sonraki Sayfa
                  InkWell(
                    onTap: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: _currentPage < totalPages - 1 ? Colors.white : Colors.grey.shade100,
                      ),
                      child: Icon(Icons.chevron_right, color: _currentPage < totalPages - 1 ? Colors.black87 : Colors.grey),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// --- GRUPLANMIŞ MÜRETTEBAT KARTI ---
class _GroupedCrewCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final Function(Map<String, dynamic>) onEdit;
  final Function(int) onDelete;

  const _GroupedCrewCard({required this.group, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final assignments = group['assignments'] as List;
    // Benzersiz rolleri bul
    final roles = assignments.map((a) => a['role'].toString()).toSet().toList();
    final employeeID = group['employeeID'] as int; // ID'yi al

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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: Colors.teal.shade700, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  group['employee'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // --- DELETE ICON ---
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => onDelete(employeeID),
                tooltip: 'Çalışanı Sil',
              ),
            ],
          ),
          
          const Divider(height: 24),
          
          const Text(
            "Atanmış Görevler",
            style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: roles.map((role) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Text(
                "#$role",
                style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.w600),
              ),
            )).toList(),
          ),
          
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: assignments.length,
              itemBuilder: (context, i) {
                final a = assignments[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.flight_takeoff, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          a['flight'],
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Edit/Delete for specific assignment could go here
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
