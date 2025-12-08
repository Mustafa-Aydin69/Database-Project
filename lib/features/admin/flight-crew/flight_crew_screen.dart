import 'package:flutter/material.dart';
import 'dart:math';

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

  // --- SABİT LİSTELER (React'ten alındı) ---
  final List<String> _flights = [
    'TK101 - IST → AYT',
    'PC202 - SAW → ADB',
    'TK303 - IST → JFK',
    'AJ404 - ESB → TZX'
  ];
  final List<String> _employees = [
    'Ahmet Yılmaz',
    'Mehmet Kaya',
    'Ayşe Demir',
    'Fatma Çelik',
    'Can Öztürk',
    'Ali Veli',
    'Zeynep Yılmaz'
  ];
  final List<String> _roles = [
    'Kaptan Pilot',
    'Yardımcı Pilot',
    'Kabin Amiri',
    'Hostes',
    'Steward'
  ];

  // --- MOCK VERİLER ---
  List<Map<String, dynamic>> _crews = [
    {'crewID': 1, 'flight': 'TK101 - IST → AYT', 'employee': 'Ahmet Yılmaz', 'role': 'Kaptan Pilot'},
    {'crewID': 2, 'flight': 'TK101 - IST → AYT', 'employee': 'Mehmet Kaya', 'role': 'Yardımcı Pilot'},
    {'crewID': 3, 'flight': 'TK101 - IST → AYT', 'employee': 'Ayşe Demir', 'role': 'Kabin Amiri'},
    {'crewID': 4, 'flight': 'PC202 - SAW → ADB', 'employee': 'Fatma Çelik', 'role': 'Kaptan Pilot'},
    {'crewID': 5, 'flight': 'PC202 - SAW → ADB', 'employee': 'Can Öztürk', 'role': 'Hostes'},
    // Sayfalama için ek veri
    ...List.generate(15, (index) => {
      'crewID': 6 + index,
      'flight': index % 2 == 0 ? 'TK303 - IST → JFK' : 'AJ404 - ESB → TZX',
      'employee': 'Personel ${index + 1}',
      'role': index % 3 == 0 ? 'Hostes' : 'Steward'
    }),
  ];

  // --- FİLTRELEME ---
  List<Map<String, dynamic>> get _filteredCrews {
    return _crews.where((c) {
      final matchesSearch = c['employee'].toString().toLowerCase().contains(_searchTerm.toLowerCase()) ||
          c['role'].toString().toLowerCase().contains(_searchTerm.toLowerCase());
      final matchesFlight = _filterFlight.isEmpty || c['flight'] == _filterFlight;
      return matchesSearch && matchesFlight;
    }).toList();
  }

  // --- CRUD İŞLEMLERİ ---

  void _showCrewDialog({Map<String, dynamic>? crew}) {
    if (crew != null) {
      _selectedFlight = crew['flight'];
      _selectedEmployee = crew['employee'];
      _selectedRole = crew['role'];
    } else {
      _selectedFlight = null;
      _selectedEmployee = null;
      _selectedRole = null;
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
                  DropdownButtonFormField<String>(
                    value: _selectedFlight,
                    decoration: const InputDecoration(
                      labelText: "Uçuş",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flight),
                    ),
                    items: _flights.map((f) => DropdownMenuItem(value: f, child: Text(f, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) => setState(() => _selectedFlight = val),
                    validator: (v) => v == null ? "Seçiniz" : null,
                    isExpanded: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedEmployee,
                    decoration: const InputDecoration(
                      labelText: "Çalışan",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: _employees.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setState(() => _selectedEmployee = val),
                    validator: (v) => v == null ? "Seçiniz" : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: "Rol",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                    items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) => setState(() => _selectedRole = val),
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
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  if (crew != null) {
                    // Güncelle
                    final index = _crews.indexWhere((c) => c['crewID'] == crew['crewID']);
                    _crews[index] = {
                      'crewID': crew['crewID'],
                      'flight': _selectedFlight,
                      'employee': _selectedEmployee,
                      'role': _selectedRole,
                    };
                  } else {
                    // Ekle
                    _crews.insert(0, {
                      'crewID': DateTime.now().millisecondsSinceEpoch,
                      'flight': _selectedFlight,
                      'employee': _selectedEmployee,
                      'role': _selectedRole,
                    });
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text(crew != null ? "Güncelle" : "Ekle"),
          ),
        ],
      ),
    );
  }

  void _deleteCrew(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Bu mürettebat kaydını silmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          TextButton(
            onPressed: () {
              setState(() => _crews.removeWhere((c) => c['crewID'] == id));
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
    final filtered = _filteredCrews;
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

            // --- KART LİSTESİ ---
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
                      childAspectRatio: 2.2,
                    ),
                    itemCount: currentData.length,
                    itemBuilder: (context, index) {
                      return _CrewCard(
                        crew: currentData[index],
                        onEdit: () => _showCrewDialog(crew: currentData[index]),
                        onDelete: () => _deleteCrew(currentData[index]['crewID']),
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

// --- MÜRETTEBAT KARTI ---
class _CrewCard extends StatelessWidget {
  final Map<String, dynamic> crew;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CrewCard({required this.crew, required this.onEdit, required this.onDelete});

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
                  crew['flight'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(4)),
                child: Text("#${crew['crewID']}", style: TextStyle(fontSize: 11, color: Colors.teal.shade700)),
              ),
            ],
          ),

          const Divider(height: 16),

          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(crew['employee'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.badge, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(crew['role'], style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
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