import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';

class ParkingLotsListScreen extends StatefulWidget {
  const ParkingLotsListScreen({super.key});

  @override
  State<ParkingLotsListScreen> createState() => _ParkingLotsListScreenState();
}

class _ParkingLotsListScreenState extends State<ParkingLotsListScreen> {
  String _searchTerm = "";
  String _filterAirport = "";

  // Sabit Listeler
  final List<String> _airports = ['İstanbul Havalimanı (IST)', 'Sabiha Gökçen (SAW)', 'Antalya Havalimanı (AYT)', 'Esenboğa (ESB)'];

  // --- MOCK VERİLER ---
  final List<Map<String, dynamic>> _parkingLots = [
    {'id': 1, 'airportName': 'İstanbul Havalimanı (IST)', 'lotName': 'A Terminali Otopark', 'totalSpots': 125, 'occupiedSpots': 87, 'blocks': ['A', 'B', 'C', 'D', 'E']},
    {'id': 2, 'airportName': 'İstanbul Havalimanı (IST)', 'lotName': 'B Terminali Otopark', 'totalSpots': 125, 'occupiedSpots': 64, 'blocks': ['A', 'B', 'C', 'D', 'E']},
    {'id': 3, 'airportName': 'Sabiha Gökçen (SAW)', 'lotName': 'Açık Otopark', 'totalSpots': 125, 'occupiedSpots': 92, 'blocks': ['A', 'B', 'C', 'D', 'E']},
    {'id': 4, 'airportName': 'Sabiha Gökçen (SAW)', 'lotName': 'Kapalı Otopark', 'totalSpots': 125, 'occupiedSpots': 45, 'blocks': ['A', 'B', 'C', 'D', 'E']},
    {'id': 5, 'airportName': 'Antalya Havalimanı (AYT)', 'lotName': 'Kapalı Otopark', 'totalSpots': 125, 'occupiedSpots': 103, 'blocks': ['A', 'B', 'C', 'D', 'E']},
    {'id': 6, 'airportName': 'Antalya Havalimanı (AYT)', 'lotName': 'VIP Otopark', 'totalSpots': 125, 'occupiedSpots': 28, 'blocks': ['A', 'B', 'C', 'D', 'E']},
    {'id': 7, 'airportName': 'Esenboğa (ESB)', 'lotName': 'Terminal Otopark', 'totalSpots': 125, 'occupiedSpots': 76, 'blocks': ['A', 'B', 'C', 'D', 'E']},
    {'id': 8, 'airportName': 'Esenboğa (ESB)', 'lotName': 'Uzun Süreli Otopark', 'totalSpots': 125, 'occupiedSpots': 51, 'blocks': ['A', 'B', 'C', 'D', 'E']},
  ];

  // --- FİLTRELEME ---
  List<Map<String, dynamic>> get _filteredLots {
    return _parkingLots.where((lot) {
      final matchesSearch = lot['lotName'].toString().toLowerCase().contains(_searchTerm.toLowerCase()) ||
          lot['airportName'].toString().toLowerCase().contains(_searchTerm.toLowerCase());
      final matchesAirport = _filterAirport.isEmpty || lot['airportName'] == _filterAirport;
      return matchesSearch && matchesAirport;
    }).toList();
  }

  Color _getOccupancyColor(double percentage) {
    if (percentage >= 90) return Colors.red;
    if (percentage >= 70) return Colors.orange;
    return Colors.green;
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
                      SizedBox(
                        width: isMobile ? double.infinity : 250,
                        child: DropdownButtonFormField<String>(
                          value: _filterAirport.isEmpty ? null : _filterAirport,
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12), hintText: "Tüm Havalimanları"),
                          items: [
                            const DropdownMenuItem(value: "", child: Text("Tüm Havalimanları")),
                            ..._airports.map((a) => DropdownMenuItem(value: a, child: Text(a))),
                          ],
                          onChanged: (val) => setState(() => _filterAirport = val ?? ""),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // --- KART LİSTESİ ---
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 1100 ? 2 : 1; // Genişse 2 kolon
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: _filteredLots.length,
                  itemBuilder: (context, index) {
                    final lot = _filteredLots[index];
                    final double percentage = (lot['occupiedSpots'] / lot['totalSpots']) * 100;
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
                                    Text(lot['lotName'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(lot['airportName'], style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
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

                          // Progress Bar
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
                                children: [
                                  Text("Dolu: ${lot['occupiedSpots']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text("Toplam: ${lot['totalSpots']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),

                          // Bloklar
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Bloklar", style: TextStyle(color: Colors.grey, fontSize: 13)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: (lot['blocks'] as List<String>).map((block) => Container(
                                  width: 36, height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                  child: Text(block, style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold)),
                                )).toList(),
                              ),
                            ],
                          ),

                          // Buton
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Detay sayfasına git (Query Param ile)
                                context.go(Uri(path: '/parking/parking-lot-detail', queryParameters: {'name': lot['lotName'], 'airport': lot['airportName']}).toString());
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
            ),
          ],
        ),
      ),
    );
  }
}