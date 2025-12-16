import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ParkingLotDetailScreen extends StatefulWidget {
  final String lotName;
  final String airportName;

  const ParkingLotDetailScreen({super.key, required this.lotName, required this.airportName});

  @override
  State<ParkingLotDetailScreen> createState() => _ParkingLotDetailScreenState();
}

class _ParkingLotDetailScreenState extends State<ParkingLotDetailScreen> {
  String _selectedBlock = "A";
  String _filterStatus = "all"; // all, available, occupied, reserved, maintenance

  // Blok Listesi
  final List<String> _blocks = ['A', 'B', 'C', 'D', 'E'];

  // --- MOCK VERİLER (Dinamik Üretim) ---
  List<Map<String, dynamic>> _generateSpots(String block) {
    List<String> statuses = ['available', 'occupied', 'reserved', 'maintenance'];
    return List.generate(25, (index) {
      String status = statuses[index % 4]; // Rastgele dağılım
      // Biraz daha gerçekçi olması için occupied ağırlıklı yapalım
      if (index % 2 == 0) status = 'occupied';
      if (index % 5 == 0) status = 'available';

      return {
        'code': '$block-${(index + 1).toString().padLeft(2, '0')}',
        'block': block,
        'status': status,
        'vehiclePlate': status == 'occupied' ? '34 ABC ${100 + index}' : null,
        'entryTime': status == 'occupied' ? '10:30' : null,
      };
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available': return Colors.green;
      case 'occupied': return Colors.red;
      case 'reserved': return Colors.amber;
      case 'maintenance': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'available': return 'Boş';
      case 'occupied': return 'Dolu';
      case 'reserved': return 'Rezerve';
      case 'maintenance': return 'Bakımda';
      default: return '';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'available': return Icons.check_circle_outline;
      case 'occupied': return Icons.directions_car;
      case 'reserved': return Icons.access_time;
      case 'maintenance': return Icons.build;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSpots = _generateSpots(_selectedBlock);
    final filteredSpots = _filterStatus == 'all' ? allSpots : allSpots.where((s) => s['status'] == _filterStatus).toList();

    // İstatistikler
    int total = allSpots.length;
    int available = allSpots.where((s) => s['status'] == 'available').length;
    int occupied = allSpots.where((s) => s['status'] == 'occupied').length;
    int reserved = allSpots.where((s) => s['status'] == 'reserved').length;
    int maintenance = allSpots.where((s) => s['status'] == 'maintenance').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.lotName, style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.airportName, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // --- İSTATİSTİK KARTLARI ---
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 1000 ? 5 : (constraints.maxWidth > 600 ? 3 : 2);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StatCard(label: "Toplam", value: "$total", icon: Icons.local_parking, color: Colors.orange),
                    _StatCard(label: "Boş", value: "$available", icon: Icons.check_circle_outline, color: Colors.green),
                    _StatCard(label: "Dolu", value: "$occupied", icon: Icons.directions_car, color: Colors.red),
                    _StatCard(label: "Rezerve", value: "$reserved", icon: Icons.access_time, color: Colors.amber),
                    _StatCard(label: "Bakımda", value: "$maintenance", icon: Icons.build, color: Colors.grey),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // --- FİLTRELER (Blok ve Durum) ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Blok Seçimi
                  const Text("Blok Seçimi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _blocks.map((block) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          onTap: () => setState(() => _selectedBlock = block),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedBlock == block ? Colors.orange.shade600 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text("Blok $block", style: TextStyle(color: _selectedBlock == block ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      )).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Durum Filtresi
                  const Text("Durum Filtresi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 250,
                    child: DropdownButtonFormField<String>(
                      value: _filterStatus,
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                      items: const [
                        DropdownMenuItem(value: "all", child: Text("Tüm Durumlar")),
                        DropdownMenuItem(value: "available", child: Text("Boş")),
                        DropdownMenuItem(value: "occupied", child: Text("Dolu")),
                        DropdownMenuItem(value: "reserved", child: Text("Rezerve")),
                        DropdownMenuItem(value: "maintenance", child: Text("Bakımda")),
                      ],
                      onChanged: (val) => setState(() => _filterStatus = val!),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- PARK YERLERİ GRID ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Blok $_selectedBlock - Park Yerleri", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),

                  filteredSpots.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Bu kriterde park yeri yok.")))
                      : LayoutBuilder(
                    builder: (context, constraints) {
                      // Park yeri kutuları
                      int crossAxisCount = constraints.maxWidth > 1000 ? 5 : (constraints.maxWidth > 600 ? 3 : 2);
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.0, // Kare
                        ),
                        itemCount: filteredSpots.length,
                        itemBuilder: (context, index) {
                          final spot = filteredSpots[index];
                          return _ParkingSpotBox(
                            spot: spot,
                            color: _getStatusColor(spot['status']),
                            icon: _getStatusIcon(spot['status']),
                            label: _getStatusLabel(spot['status']),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- YARDIMCI WIDGETLAR ---

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}

class _ParkingSpotBox extends StatelessWidget {
  final Map<String, dynamic> spot;
  final Color color;
  final IconData icon;
  final String label;

  const _ParkingSpotBox({required this.spot, required this.color, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Durum İkonu (Sağ üst köşe yerine merkeze yakın)
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),

          // Kod
          Text(spot['code'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

          const SizedBox(height: 4),

          // Durum Yazısı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),

          // Eğer doluysa plaka göster
          if (spot['status'] == 'occupied') ...[
            const SizedBox(height: 8),
            Text(spot['vehiclePlate'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            Text(spot['entryTime'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ]
        ],
      ),
    );
  }
}