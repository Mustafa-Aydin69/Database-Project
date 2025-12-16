import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'models/parking_lot_detail_response.dart';
import 'services/parking_lot_detail_api.dart';

class ParkingLotDetailScreen extends StatefulWidget {
  final int parkingLotId;
  const ParkingLotDetailScreen({super.key, required this.parkingLotId});

  @override
  State<ParkingLotDetailScreen> createState() => _ParkingLotDetailScreenState();
}

class _ParkingLotDetailScreenState extends State<ParkingLotDetailScreen> {
  String _filterStatus = 'all';
  String? _selectedTerminalCode;
  Future<ParkingLotDetailResponse>? _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = ParkingLotDetailApi.fetchDetail(widget.parkingLotId);
  }

  Color _statusColor(String status) {
    final s = status.toUpperCase();
    if (s == 'OCCUPIED') return Colors.red;
    return Colors.green;
  }

  String _statusLabel(String status) {
    final s = status.toUpperCase();
    if (s == 'OCCUPIED') return 'Dolu';
    return 'Boş';
  }

  IconData _statusIcon(String status) {
    final s = status.toUpperCase();
    if (s == 'OCCUPIED') return Icons.directions_car;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: FutureBuilder<ParkingLotDetailResponse>(
          future: _detailFuture,
          builder: (context, snapshot) {
            final lotName = snapshot.hasData ? snapshot.data!.summary.lotName : 'Otopark Detayı';
            return Text(lotName, style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold));
          },
        ),
      ),
      body: FutureBuilder<ParkingLotDetailResponse>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Detay verisi alınamadı', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), style: TextStyle(color: Colors.grey.shade600, fontSize: 12), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: () => setState(() {}), child: const Text('Tekrar Dene')),
                ],
              ),
            );
          }
          final data = snapshot.data!;
          final terminals = data.terminals;
          final spots = data.spots;
          final currentTerminalCode = _selectedTerminalCode ?? (terminals.isNotEmpty ? terminals.first.terminalCode : null);
          final filteredSpots = spots
              .where((s) => currentTerminalCode == null || s.terminalCode == currentTerminalCode)
              .where((s) {
                if (_filterStatus == 'all') return true;
                final st = s.spotStatus.toUpperCase();
                if (_filterStatus == 'OCCUPIED') return st == 'OCCUPIED';
                if (_filterStatus == 'EMPTY') return st == 'EMPTY';
                return true;
              })
              .toList();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final summary = data.summary;
                    final total = summary.totalSpots;
                    final available = summary.emptyCount;
                    final occupied = summary.occupiedCount;
                    final reserved = summary.reservedCount;
                    final maintenance = summary.maintenanceCount;
                    int crossAxisCount = constraints.maxWidth > 1000 ? 5 : (constraints.maxWidth > 600 ? 3 : 2);
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _StatCard(label: 'Toplam', value: '$total', icon: Icons.local_parking, color: Colors.orange),
                        _StatCard(label: 'Boş', value: '$available', icon: Icons.check_circle_outline, color: Colors.green),
                        _StatCard(label: 'Dolu', value: '$occupied', icon: Icons.directions_car, color: Colors.red),
                        _StatCard(label: 'Rezerve', value: '$reserved', icon: Icons.access_time, color: Colors.amber),
                        _StatCard(label: 'Bakımda', value: '$maintenance', icon: Icons.build, color: Colors.grey),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Terminal Seçimi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: terminals.map((t) {
                            final selected = currentTerminalCode == t.terminalCode;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: InkWell(
                                onTap: () => setState(() => _selectedTerminalCode = t.terminalCode),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(color: selected ? Colors.orange.shade600 : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                  child: Text(t.terminalCode, style: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Durum Filtresi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 250,
                        child: DropdownButtonFormField<String>(
                          value: _filterStatus,
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('Tüm Durumlar')),
                            DropdownMenuItem(value: 'EMPTY', child: Text('Boş')),
                            DropdownMenuItem(value: 'OCCUPIED', child: Text('Dolu')),
                          ],
                          onChanged: (val) => setState(() => _filterStatus = val ?? 'all'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentTerminalCode == null ? 'Park Yerleri' : 'Terminal $currentTerminalCode - Park Yerleri', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 16),
                      filteredSpots.isEmpty
                          ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Bu kriterde park yeri yok.')))
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                int crossAxisCount = constraints.maxWidth > 1000 ? 5 : (constraints.maxWidth > 600 ? 3 : 2);
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1.0,
                                  ),
                                  itemCount: filteredSpots.length,
                                  itemBuilder: (context, index) {
                                    final spot = filteredSpots[index];
                                    final color = _statusColor(spot.spotStatus);
                                    final icon = _statusIcon(spot.spotStatus);
                                    final label = _statusLabel(spot.spotStatus);
                                    return _ParkingSpotBox(spotNumber: spot.spotNumber, color: color, icon: icon, label: label);
                                  },
                                );
                              },
                            ),
                    ],
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
  final String spotNumber;
  final Color color;
  final IconData icon;
  final String label;
  const _ParkingSpotBox({required this.spotNumber, required this.color, required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.5), width: 1.5)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(spotNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
