import 'package:flutter/material.dart';

class ParkingDashboardScreen extends StatefulWidget {
  const ParkingDashboardScreen({super.key});

  @override
  State<ParkingDashboardScreen> createState() => _ParkingDashboardScreenState();
}

class _ParkingDashboardScreenState extends State<ParkingDashboardScreen> {

  @override
  Widget build(BuildContext context) {
    // --- MOCK VERİLER (React'ten) ---
    final kpiData = {
      'totalSpots': 342,
      'occupiedSpots': 218,
      'availableSpots': 124,
      'activeReservations': 45,
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

    final parkingLots = [
      {'name': 'A Blok', 'total': 100, 'occupied': 68, 'available': 32, 'percentage': 0.68}, // 0.68 = %68
      {'name': 'B Blok', 'total': 80, 'occupied': 52, 'available': 28, 'percentage': 0.65},
      {'name': 'C Blok', 'total': 90, 'occupied': 58, 'available': 32, 'percentage': 0.64},
      {'name': 'D Blok', 'total': 72, 'occupied': 40, 'available': 32, 'percentage': 0.56},
    ];

    final recentEntries = [
      {'id': 1, 'plate': '34 ABC 123', 'vehicleType': 'Otomobil', 'entryTime': '14:30', 'spot': 'A-45'},
      {'id': 2, 'plate': '06 XYZ 789', 'vehicleType': 'SUV', 'entryTime': '14:15', 'spot': 'B-12'},
      {'id': 3, 'plate': '35 DEF 456', 'vehicleType': 'Otomobil', 'entryTime': '13:45', 'spot': 'C-28'},
      {'id': 4, 'plate': '16 GHI 321', 'vehicleType': 'Minivan', 'entryTime': '13:20', 'spot': 'A-67'},
      {'id': 5, 'plate': '41 JKL 654', 'vehicleType': 'Otomobil', 'entryTime': '12:50', 'spot': 'D-15'},
    ];

    final recentExits = [
      {'id': 1, 'plate': '34 MNO 987', 'vehicleType': 'Otomobil', 'exitTime': '14:25', 'duration': '3s 15dk', 'amount': '₺85'},
      {'id': 2, 'plate': '06 PQR 654', 'vehicleType': 'SUV', 'exitTime': '14:10', 'duration': '2s 45dk', 'amount': '₺120'},
      {'id': 3, 'plate': '35 STU 321', 'vehicleType': 'Otomobil', 'exitTime': '13:55', 'duration': '4s 20dk', 'amount': '₺95'},
      {'id': 4, 'plate': '16 VWX 159', 'vehicleType': 'Minivan', 'exitTime': '13:30', 'duration': '5s 10dk', 'amount': '₺150'},
    ];

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

                  // Bloklar Grid'i
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int cols = constraints.maxWidth > 1000 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: 1.5, // Kart oranı
                        ),
                        itemCount: parkingLots.length,
                        itemBuilder: (context, index) {
                          final lot = parkingLots[index];
                          return _ParkingLotProgress(
                            name: lot['name'] as String,
                            percentage: lot['percentage'] as double,
                            occupied: lot['occupied'] as int,
                            available: lot['available'] as int,
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
                      Expanded(child: _EntriesTable(entries: recentEntries)),
                      const SizedBox(width: 24),
                      Expanded(child: _ExitsTable(exits: recentExits)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _EntriesTable(entries: recentEntries),
                      const SizedBox(height: 24),
                      _ExitsTable(exits: recentExits),
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