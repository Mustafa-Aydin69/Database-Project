import 'package:flutter/material.dart';
import 'dart:convert';
import 'models/recent_checkout.dart';
import 'services/recent_checkouts_api.dart';
import 'models/recent_checkin_model.dart';
import 'services/recent_checkins_api.dart';
import 'models/dashboard_kpi_model.dart';
import 'services/parking_dashboard_api.dart';
import 'models/parking_lot_occupancy_model.dart';
import 'services/parking_lot_occupancy_api.dart';

class ParkingDashboardScreen extends StatefulWidget {
  const ParkingDashboardScreen({super.key});

  @override
  State<ParkingDashboardScreen> createState() => _ParkingDashboardScreenState();
}

class _ParkingDashboardScreenState extends State<ParkingDashboardScreen> {
  Future<List<RecentCheckout>>? _checkoutsFuture;
  bool _showJsonExits = false;
  DashboardKpiModel? _kpi;
  String? _kpiError;
  Future<List<ParkingLotOccupancyModel>>? _occupancyFuture;
  String? _occupancyError;
  Future<List<RecentCheckInModel>>? _entriesFuture;

  @override
  void initState() {
    super.initState();
    _loadCheckouts();
    _loadKpi();
    _loadOccupancy();
    _loadEntries();
  }

  void _loadCheckouts() {
    setState(() {
      _checkoutsFuture = RecentCheckoutsApi.fetchRecentCheckouts();
    });
  }

  Future<void> _loadKpi() async {
    try {
      final result = await ParkingDashboardApi.fetchKpi();
      setState(() {
        _kpi = result;
        _kpiError = null;
      });
    } catch (e) {
      setState(() {
        _kpi = null;
        _kpiError = e.toString();
      });
    }
  }

  void _loadOccupancy() {
    setState(() {
      _occupancyFuture = ParkingLotOccupancyApi.fetchOccupancy();
      _occupancyError = null;
    });
  }

  void _loadEntries({int topN = 5}) {
    setState(() {
      _entriesFuture = RecentCheckInsApi.fetchRecentCheckIns(topN: topN);
    });
  }

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0) {
      return '${h}s ${m}dk';
    }
    return '${m}dk';
  }

  String _formatTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _formatTL(double amount) {
    return '₺${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    // --- KPI VERİLERİ (API) ---
    final kpiData = {
      'totalSpots': _kpi?.totalSpots ?? 0,
      'occupiedSpots': _kpi?.occupiedSpots ?? 0,
      'availableSpots': _kpi?.freeSpots ?? 0,
      'activeReservations': _kpi?.activeReservations ?? 0,
    };

    final stats = [
      {
        'icon': Icons.directions_car_outlined, // ri-car-line
        'label': 'Toplam Park Yeri',
        'value': kpiData['totalSpots'].toString(),
        'bgColor': Colors.orange.shade50,
        'iconColor': Colors.orange.shade600,
      },
      {
        'icon': Icons.local_parking, // ri-parking-box-fill
        'label': 'Dolu Park Yerleri',
        'value': kpiData['occupiedSpots'].toString(),
        'bgColor': Colors.red.shade50,
        'iconColor': Colors.red.shade600,
      },
      {
        'icon': Icons.local_parking_outlined, // ri-parking-box-line
        'label': 'Boş Park Yerleri',
        'value': kpiData['availableSpots'].toString(),
        'bgColor': Colors.green.shade50,
        'iconColor': Colors.green.shade600,
      },
      {
        'icon': Icons.event_available, // ri-calendar-check-line
        'label': 'Aktif Rezervasyonlar',
        'value': kpiData['activeReservations'].toString(),
        'bgColor': Colors.teal.shade50,
        'iconColor': Colors.teal.shade600,
      },
    ];

    final parkingLots = <Map<String, Object>>[];

    final recentEntries = <Map<String, Object>>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // bg-gray-50
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            const Text(
              "Otopark Dashboard",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              "Otopark operasyonlarına genel bakış",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            // --- 1. İSTATİSTİK KARTLARI (Responsive Grid) ---
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 1100 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: stats.length,
                  itemBuilder: (context, index) {
                    final item = stats[index];
                    return _StatCard(
                      label: item['label'] as String,
                      value: item['value'] as String,
                      icon: item['icon'] as IconData,
                      iconColor: item['iconColor'] as Color,
                      bgColor: item['bgColor'] as Color,
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // --- 2. OTOPARK BLOKLARI DURUMU (Progress Bars) ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Otopark Blokları Doluluk Oranı", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 24),

                  FutureBuilder<List<ParkingLotOccupancyModel>>(
                    future: _occupancyFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Column(
                          children: [
                            Text(
                              'Doluluk verisi alınamadı',
                              style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadOccupancy,
                              child: const Text('Tekrar Dene'),
                            ),
                          ],
                        );
                      }
                      final data = snapshot.data ?? [];
                      final mappedLots = data.map((e) {
                        final rate = e.occupancyRate > 1.0 ? e.occupancyRate / 100.0 : e.occupancyRate;
                        return {
                          'name': e.parkingLotName,
                          'total': e.totalSpots,
                          'occupied': e.occupiedSpots,
                          'available': e.freeSpots,
                          'percentage': rate,
                        };
                      }).toList();

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          int cols = constraints.maxWidth > 1000 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                              childAspectRatio: 1.5,
                            ),
                            itemCount: mappedLots.length,
                            itemBuilder: (context, index) {
                              final lot = mappedLots[index];
                              return _ParkingLotProgress(
                                name: lot['name'] as String,
                                percentage: lot['percentage'] as double,
                                occupied: lot['occupied'] as int,
                                available: lot['available'] as int,
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

            const SizedBox(height: 24),

            // --- 3. SON GİRİŞLER VE ÇIKIŞLAR (Responsive Row/Column) ---
            LayoutBuilder(
              builder: (context, constraints) {
                // Geniş ekranda yan yana, dar ekranda alt alta
                if (constraints.maxWidth > 1100) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: FutureBuilder<List<RecentCheckInModel>>(
                          future: _entriesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: const Center(child: CircularProgressIndicator()),
                              );
                            }
                            if (snapshot.hasError) {
                              return Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Veri alınamadı',
                                      style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      snapshot.error.toString(),
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () => _loadEntries(),
                                      child: const Text('Tekrar Dene'),
                                    ),
                                  ],
                                ),
                              );
                            }
                            final data = snapshot.data ?? [];
                            final entries = data
                                .map((e) => {
                                      'plate': e.plateNumber,
                                      'vehicleType': e.vehicleType,
                                      'entryTime': _formatTime(e.checkInTime),
                                      'spot': e.spot,
                                    })
                                .toList();
                            return _EntriesTable(entries: entries);
                          },
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: FutureBuilder<List<RecentCheckout>>(
                          future: _checkoutsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: const Center(child: CircularProgressIndicator()),
                              );
                            }
                            if (snapshot.hasError) {
                              return Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Veri alınamadı',
                                      style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      snapshot.error.toString(),
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: _loadCheckouts,
                                      child: const Text('Tekrar Dene'),
                                    ),
                                  ],
                                ),
                              );
                            }
                            final data = snapshot.data ?? [];
                            final exits = data
                                .map((e) => {
                                      'plate': e.plateNumber,
                                      'duration': _formatDuration(e.durationMinutes),
                                      'exitTime': _formatTime(e.checkOutTime),
                                      'amount': _formatTL(e.amount),
                                    })
                                .toList();
                            final prettyJson = const JsonEncoder.withIndent('  ').convert(
                              data.map((e) => {
                                    'plateNumber': e.plateNumber,
                                    'durationMinutes': e.durationMinutes,
                                    'checkOutTime': e.checkOutTime.toIso8601String(),
                                    'amount': e.amount,
                                  }).toList(),
                            );
                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [],
                                ),
                                _showJsonExits
                                    ? Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.vertical,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Text(
                                              prettyJson,
                                              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                            ),
                                          ),
                                        ),
                                      )
                                    : _ExitsTable(exits: exits),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      FutureBuilder<List<RecentCheckInModel>>(
                        future: _entriesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: const Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (snapshot.hasError) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Veri alınamadı',
                                    style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    snapshot.error.toString(),
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () => _loadEntries(),
                                    child: const Text('Tekrar Dene'),
                                  ),
                                ],
                              ),
                            );
                          }
                          final data = snapshot.data ?? [];
                          final entries = data
                              .map((e) => {
                                    'plate': e.plateNumber,
                                    'vehicleType': e.vehicleType,
                                    'entryTime': _formatTime(e.checkInTime),
                                    'spot': e.spot,
                                  })
                              .toList();
                          return _EntriesTable(entries: entries);
                        },
                      ),
                      const SizedBox(height: 24),
                      FutureBuilder<List<RecentCheckout>>(
                        future: _checkoutsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: const Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (snapshot.hasError) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Veri alınamadı',
                                    style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    snapshot.error.toString(),
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _loadCheckouts,
                                    child: const Text('Tekrar Dene'),
                                  ),
                                ],
                              ),
                            );
                          }
                          final data = snapshot.data ?? [];
                          final exits = data
                              .map((e) => {
                                    'plate': e.plateNumber,
                                    'duration': _formatDuration(e.durationMinutes),
                                    'exitTime': _formatTime(e.checkOutTime),
                                    'amount': _formatTL(e.amount),
                                  })
                              .toList();
                          final prettyJson = const JsonEncoder.withIndent('  ').convert(
                            data.map((e) => {
                                  'plateNumber': e.plateNumber,
                                  'durationMinutes': e.durationMinutes,
                                  'checkOutTime': e.checkOutTime.toIso8601String(),
                                  'amount': e.amount,
                                }).toList(),
                          );
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [],
                              ),
                              _showJsonExits
                                  ? Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.vertical,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Text(
                                            prettyJson,
                                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    )
                                  : _ExitsTable(exits: exits),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET 1: İSTATİSTİK KARTI ---
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _StatCard({required this.label, required this.value, required this.icon, required this.iconColor, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87)),
        ],
      ),
    );
  }
}

// --- WIDGET 2: OTOPARK PROGRESS BAR ---
class _ParkingLotProgress extends StatelessWidget {
  final String name;
  final double percentage;
  final int occupied;
  final int available;

  const _ParkingLotProgress({required this.name, required this.percentage, required this.occupied, required this.available});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text("%${(percentage * 100).toInt()}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 8),
        // Custom Progress Bar
        Stack(
          children: [
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: 12,
                  width: constraints.maxWidth * percentage,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Dolu: $occupied", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text("Boş: $available", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ],
    );
  }
}

// --- WIDGET 3: SON GİRİŞLER TABLOSU ---
class _EntriesTable extends StatelessWidget {
  final List<Map<String, Object>> entries;
  const _EntriesTable({required this.entries});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Align(alignment: Alignment.centerLeft, child: Text("Son Girişler", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          ),
          const Divider(height: 1),
          // Başlıklar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text("Plaka", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
                if (!isMobile) Expanded(flex: 2, child: Text("Araç Tipi", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
                Expanded(flex: 1, child: Text("Saat", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
                Expanded(flex: 1, child: Text("Yer", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
              ],
            ),
          ),
          const Divider(height: 1),
          // Liste
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = entries[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['plate'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
                          if (isMobile) Text(item['vehicleType'] as String, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    if (!isMobile) Expanded(flex: 2, child: Text(item['vehicleType'] as String, style: TextStyle(color: Colors.grey.shade700, fontSize: 13))),
                    Expanded(flex: 1, child: Text(item['entryTime'] as String, style: const TextStyle(fontSize: 13))),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Text(item['spot'] as String, style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// --- WIDGET 4: SON ÇIKIŞLAR TABLOSU ---
class _ExitsTable extends StatelessWidget {
  final List<Map<String, Object>> exits;
  const _ExitsTable({required this.exits});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Align(alignment: Alignment.centerLeft, child: Text("Son Çıkışlar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          ),
          const Divider(height: 1),
          // Başlıklar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text("Plaka", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
                if (!isMobile) Expanded(flex: 2, child: Text("Süre", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
                Expanded(flex: 1, child: Text("Saat", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
                Expanded(flex: 1, child: Text("Tutar", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
              ],
            ),
          ),
          const Divider(height: 1),
          // Liste
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: exits.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = exits[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['plate'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
                          if (isMobile) Text(item['duration'] as String, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    if (!isMobile) Expanded(flex: 2, child: Text(item['duration'] as String, style: TextStyle(color: Colors.grey.shade700, fontSize: 13))),
                    Expanded(flex: 1, child: Text(item['exitTime'] as String, style: const TextStyle(fontSize: 13))),
                    Expanded(
                      flex: 1,
                      child: Text(item['amount'] as String, style: TextStyle(fontSize: 13, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
