import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../entry-exit/models/parking_lot_dropdown_item.dart';
import '../entry-exit/services/parking_lots_api.dart';
import 'models/parking_lot_occupancy.dart';

class ParkingLotsListScreen extends StatefulWidget {
  const ParkingLotsListScreen({super.key});

  @override
  State<ParkingLotsListScreen> createState() => _ParkingLotsListScreenState();
}

class _ParkingLotsListScreenState extends State<ParkingLotsListScreen> {
  String _searchTerm = "";
  int? _selectedParkingLotId;
  String? _selectedParkingLotName;
  Future<List<ParkingLotDropdownItem>>? _parkingLotsFuture;
  String _filterAirport = "";
  Future<List<ParkingLotOccupancy>>? _lotsFuture;
  Map<String, int> _lotIdByName = {};

  // Sabit Listeler
  final List<String> _airports = ['İstanbul Havalimanı (IST)', 'Sabiha Gökçen (SAW)', 'Antalya Havalimanı (AYT)', 'Esenboğa (ESB)'];

  // --- FİLTRELEME ---
  List<ParkingLotOccupancy> _filterLots(List<ParkingLotOccupancy> lots) {
    final term = _searchTerm.toLowerCase();
    return lots.where((lot) {
      final matchesSearch = lot.lotName.toLowerCase().contains(term);
      final matchesSelection = _selectedParkingLotName == null || lot.lotName == _selectedParkingLotName;
      return matchesSearch && matchesSelection;
    }).toList();
  }

  Color _getOccupancyColor(double percentage) {
    if (percentage >= 90) return Colors.red;
    if (percentage >= 70) return Colors.orange;
    return Colors.green;
  }

  @override
  void initState() {
    super.initState();
    _parkingLotsFuture = ParkingLotsApi.fetch();
    _lotsFuture = ParkingLotsApi.fetchParkingLotsWithOccupancy();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Otopark Listesi", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                SizedBox(height: 4),
                Text("Tüm havalimanlarındaki otopark alanlarını görüntüleyin", style: TextStyle(color: Colors.grey)),
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
                            hintText: "Otopark veya havalimanı ara...",
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
                      isMobile
                          ? SizedBox(
                              width: double.infinity,
                              child: FutureBuilder<List<ParkingLotDropdownItem>>(
                                future: _parkingLotsFuture,
                                builder: (context, snap) {
                                  if (snap.connectionState == ConnectionState.waiting) {
                                    return SizedBox(
                                      height: 48,
                                      child: InputDecorator(
                                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12), hintText: "Otopark seçin"),
                                        child: Row(
                                          children: const [
                                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                            SizedBox(width: 8),
                                            Text("Yükleniyor...")
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  if (snap.hasError) {
                                    return InputDecorator(
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                        hintText: "Otopark seçin",
                                        errorText: "Otopark listesi yüklenemedi",
                                      ),
                                      child: const SizedBox.shrink(),
                                    );
                                  }
                                  final items = snap.data ?? [];
                                  if (items.isEmpty) {
                                    return InputDecorator(
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                        hintText: "Otopark seçin",
                                        errorText: "Otopark listesi bulunamadı",
                                      ),
                                      child: const SizedBox.shrink(),
                                    );
                                  }
                                  if (_lotIdByName.isEmpty) {
                                    final map = <String, int>{};
                                    for (final e in items) {
                                      map[e.lotName] = e.parkingLotID;
                                    }
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (mounted) setState(() => _lotIdByName = map);
                                    });
                                  }
                                  return DropdownButtonFormField<int>(
                                    isExpanded: true,
                                    value: _selectedParkingLotId,
                                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12), hintText: "Otopark seçin"),
                                    items: items
                                        .map((e) => DropdownMenuItem<int>(
                                              value: e.parkingLotID,
                                              child: Text(
                                                e.lotName,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedParkingLotId = val;
                                        String? name;
                                        for (final e in items) {
                                          if (e.parkingLotID == val) {
                                            name = e.lotName;
                                            break;
                                          }
                                        }
                                        _selectedParkingLotName = name;
                                      });
                                    },
                                  );
                                },
                              ),
                            )
                          : Flexible(
                              child: FutureBuilder<List<ParkingLotDropdownItem>>(
                                future: _parkingLotsFuture,
                                builder: (context, snap) {
                                  if (snap.connectionState == ConnectionState.waiting) {
                                    return SizedBox(
                                      height: 48,
                                      child: InputDecorator(
                                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12), hintText: "Otopark seçin"),
                                        child: Row(
                                          children: const [
                                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                            SizedBox(width: 8),
                                            Text("Yükleniyor...")
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  if (snap.hasError) {
                                    return InputDecorator(
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                        hintText: "Otopark seçin",
                                        errorText: "Otopark listesi yüklenemedi",
                                      ),
                                      child: const SizedBox.shrink(),
                                    );
                                  }
                                  final items = snap.data ?? [];
                                  if (items.isEmpty) {
                                    return InputDecorator(
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                        hintText: "Otopark seçin",
                                        errorText: "Otopark listesi bulunamadı",
                                      ),
                                      child: const SizedBox.shrink(),
                                    );
                                  }
                                  if (_lotIdByName.isEmpty) {
                                    final map = <String, int>{};
                                    for (final e in items) {
                                      map[e.lotName] = e.parkingLotID;
                                    }
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (mounted) setState(() => _lotIdByName = map);
                                    });
                                  }
                                  return DropdownButtonFormField<int>(
                                    isExpanded: true,
                                    value: _selectedParkingLotId,
                                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12), hintText: "Otopark seçin"),
                                    items: items
                                        .map((e) => DropdownMenuItem<int>(
                                              value: e.parkingLotID,
                                              child: Text(
                                                e.lotName,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedParkingLotId = val;
                                        String? name;
                                        for (final e in items) {
                                          if (e.parkingLotID == val) {
                                            name = e.lotName;
                                            break;
                                          }
                                        }
                                        _selectedParkingLotName = name;
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // --- KART LİSTESİ (GERÇEK VERİ) ---
            FutureBuilder<List<ParkingLotOccupancy>>(
              future: _lotsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Otopark verileri yüklenemedi", style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(snapshot.error.toString(), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  );
                }
                final allLots = snapshot.data ?? [];
                final filtered = _filterLots(allLots);
                return LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth > 1100 ? 2 : 1;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: 1.8,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final lot = filtered[index];
                        final percentage = lot.occupancyRate;
                        final color = _getOccupancyColor(percentage);
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(lot.lotName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                                    child: Icon(Icons.local_parking, color: Colors.orange.shade700, size: 28),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Doluluk Oranı", style: TextStyle(color: Colors.grey)),
                                      Text("${percentage.toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: percentage / 100,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(color),
                                      minHeight: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: const [
                                      Text("Dolu: —", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text("Toplam: —", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    final id = _lotIdByName[lot.lotName];
                                    if (id != null) {
                                      context.go(Uri(path: '/parking/parking-lot-detail', queryParameters: {'parkingLotId': id.toString()}).toString());
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.visibility),
                                  label: const Text("Detayları Görüntüle"),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
