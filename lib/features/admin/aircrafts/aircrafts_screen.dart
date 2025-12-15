import 'package:flutter/material.dart';
import 'models/aircraft.dart';
import 'services/aircraft_service.dart';
import 'models/airline_option.dart';
import 'services/airline_service.dart';

class AircraftsScreen extends StatefulWidget {
  const AircraftsScreen({super.key});

  @override
  State<AircraftsScreen> createState() => _AircraftsScreenState();
}

class _AircraftsScreenState extends State<AircraftsScreen> {
  Future<List<Aircraft>>? _future;
  List<Aircraft> _items = [];
  final Map<int, String> _airlineNames = {};

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  int? _selectedAirlineId;
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = AircraftService.getAircrafts();
    _prefetchAirlines();
  }

  Future<void> _prefetchAirlines() async {
    try {
      final list = await AirlineService.getAirlines();
      for (final AirlineOption a in list) {
        _airlineNames[a.airlineId] = a.airlineName;
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  // --- CRUD İŞLEMLERİ ---

  Future<void> _showAircraftDialog({Aircraft? aircraft}) async {
    if (aircraft != null) {
      _selectedAirlineId = aircraft.airlineId;
      _modelController.text = aircraft.model;
      _capacityController.text = aircraft.capacity.toString();
    } else {
      _selectedAirlineId = null;
      _modelController.clear();
      _capacityController.clear();
    }

    List<AirlineOption> options = [];
    try {
      options = await AirlineService.getAirlines();
    } catch (_) {
      options = [];
    }
    final dropdownItems = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(value: null, child: Text("Tanımsız / Seçme")),
      ...options.map((a) => DropdownMenuItem<int?>(value: a.airlineId, child: Text(a.airlineName))),
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(aircraft != null ? 'Uçak Düzenle' : 'Yeni Uçak'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int?>(
                    value: _selectedAirlineId,
                    decoration: const InputDecoration(
                      labelText: "Havayolu",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.airlines),
                    ),
                    items: dropdownItems,
                    onChanged: (val) => setDialogState(() => _selectedAirlineId = val),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: "Model",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flight),
                      hintText: "örn: Boeing 737-800",
                    ),
                    validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _capacityController,
                    decoration: const InputDecoration(
                      labelText: "Kapasite",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Zorunlu alan";
                      final cap = int.tryParse(v);
                      if (cap == null || cap <= 0) return "Kapasite 0'dan büyük olmalı";
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
                  if (aircraft != null) {
                    final index = _items.indexWhere((a) => a.aircraftId == aircraft.aircraftId);
                    if (index >= 0) {
                      _items[index] = Aircraft(
                        aircraftId: aircraft.aircraftId,
                        airlineId: _selectedAirlineId,
                        model: _modelController.text,
                        capacity: int.parse(_capacityController.text),
                      );
                    }
                  } else {
                    _items.insert(
                      0,
                      Aircraft(
                        aircraftId: DateTime.now().millisecondsSinceEpoch,
                        airlineId: _selectedAirlineId,
                        model: _modelController.text,
                        capacity: int.parse(_capacityController.text),
                      ),
                    );
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text(aircraft != null ? "Güncelle" : "Ekle"),
          ),
        ],
          );
        },
      ),
    );
  }

  void _deleteAircraft(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Bu uçağı silmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          TextButton(
            onPressed: () {
              setState(() {
                _items.removeWhere((a) => a.aircraftId == id);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: FutureBuilder<List<Aircraft>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Uçaklar alınamadı', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), style: TextStyle(color: Colors.grey.shade600, fontSize: 12), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: () => setState(() => _future = AircraftService.getAircrafts()), child: const Text('Tekrar Dene')),
                ],
              ),
            );
          }
          final data = snapshot.data ?? [];
          if (_items.isEmpty && data.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _items = data);
            });
          }
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Uçak Yönetimi", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                        SizedBox(height: 4),
                        Text("Uçakları yönetin", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAircraftDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text("Yeni Uçak"),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _items.isEmpty
                      ? const Center(child: Text("Kayıt bulunamadı."))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
                            return GridView.builder(
                              padding: EdgeInsets.zero,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 2.0,
                              ),
                              itemCount: _items.length,
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                final airlineSubtitle = item.airlineId == null
                                    ? "Bağımsız / Tanımsız Havayolu"
                                    : (_airlineNames[item.airlineId!] ?? "Havayolu ID: ${item.airlineId}");
                                return _AircraftCard(
                                  key: ValueKey(item.aircraftId),
                                  aircraft: item,
                                  airlineSubtitle: airlineSubtitle,
                                  onEdit: () => _showAircraftDialog(aircraft: item),
                                  onDelete: () => _deleteAircraft(item.aircraftId),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- UÇAK KARTI ---
class _AircraftCard extends StatelessWidget {
  final Aircraft aircraft;
  final String airlineSubtitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AircraftCard({super.key, required this.aircraft, required this.airlineSubtitle, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
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
                      Text(
                        aircraft.model,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        airlineSubtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Text("ID: ${aircraft.aircraftId}", style: TextStyle(fontSize: 11, color: Colors.teal.shade700)),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                const Icon(Icons.event_seat, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text("${aircraft.capacity} Kişi Kapasiteli", style: const TextStyle(fontSize: 13, color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 8),
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
      ),
    );
  }
}
