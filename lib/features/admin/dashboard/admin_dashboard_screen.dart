import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- MOCK VERİLER (React State'in Karşılığı) ---
    final kpiData = {
      'todayFlights': 47,
      'activeReservations': 234,
      'occupiedParkingSpots': 156,
      'totalRevenue': 1847500,
    };

    final stats = [
      {
        'icon': Icons.flight_takeoff,
        'label': 'Bugünkü Uçuşlar',
        'value': kpiData['todayFlights'].toString(),
        'color': Colors.teal,
        'change': '+12%',
      },
      {
        'icon': Icons.calendar_today,
        'label': 'Aktif Rezervasyonlar',
        'value': kpiData['activeReservations'].toString(),
        'color': Colors.orange,
        'change': '+8%',
      },
      {
        'icon': Icons.local_parking,
        'label': 'Dolu Park Yerleri',
        'value': kpiData['occupiedParkingSpots'].toString(),
        'color': Colors.purple,
        'change': '+5%',
      },
      {
        'icon': Icons.currency_lira, // Dolar ikonu yerine TL
        'label': 'Toplam Gelir',
        'value': "₺${_formatMoney(kpiData['totalRevenue'] as int)}",
        'color': Colors.green,
        'change': '+15%',
      },
    ];

    final todayFlights = [
      {'id': 'FL001', 'flightNo': 'TK101', 'departure': 'IST', 'arrival': 'AYT', 'time': '10:30', 'status': 'Zamanında'},
      {'id': 'FL002', 'flightNo': 'TK205', 'departure': 'IST', 'arrival': 'ADB', 'time': '11:45', 'status': 'Gecikti'},
      {'id': 'FL003', 'flightNo': 'TK301', 'departure': 'IST', 'arrival': 'ESB', 'time': '12:15', 'status': 'Zamanında'},
      {'id': 'FL004', 'flightNo': 'TK405', 'departure': 'IST', 'arrival': 'TZX', 'time': '13:00', 'status': 'Biniş'},
      {'id': 'FL005', 'flightNo': 'TK501', 'departure': 'IST', 'arrival': 'DLM', 'time': '14:20', 'status': 'Zamanında'},
    ];

    final recentReservations = [
      {'id': 'R001', 'passenger': 'Ahmet Yılmaz', 'flightNo': 'TK101', 'date': '15 Oca 2024', 'status': 'Onaylandı'},
      {'id': 'R002', 'passenger': 'Ayşe Demir', 'flightNo': 'TK205', 'date': '15 Oca 2024', 'status': 'Onaylandı'},
      {'id': 'R003', 'passenger': 'Mehmet Kaya', 'flightNo': 'TK301', 'date': '15 Oca 2024', 'status': 'Bekliyor'},
      {'id': 'R004', 'passenger': 'Fatma Şahin', 'flightNo': 'TK405', 'date': '16 Oca 2024', 'status': 'Onaylandı'},
      {'id': 'R005', 'passenger': 'Ali Öztürk', 'flightNo': 'TK501', 'date': '16 Oca 2024', 'status': 'Onaylandı'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // React: bg-gray-50
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BAŞLIK ---
            const Text(
              "Dashboard",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const Text(
              "Havalimanı operasyonlarına genel bakış",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // --- İSTATİSTİK KARTLARI (Responsive Grid) ---
            LayoutBuilder(
              builder: (context, constraints) {
                // Ekran genişliğine göre kolon sayısını belirle
                int crossAxisCount = constraints.maxWidth > 1100 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);

                return GridView.builder(
                  shrinkWrap: true, // ScrollView içinde olduğu için gerekli
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.6, // Kartın en/boy oranı
                  ),
                  itemCount: stats.length,
                  itemBuilder: (context, index) {
                    final item = stats[index];
                    return _StatCard(
                      title: item['label'] as String,
                      value: item['value'] as String,
                      icon: item['icon'] as IconData,
                      color: item['color'] as Color,
                      change: item['change'] as String,
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // --- LİSTELER (Responsive Layout) ---
            LayoutBuilder(
              builder: (context, constraints) {
                // Geniş ekranda yan yana, dar ekranda alt alta
                if (constraints.maxWidth > 1000) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _FlightsListCard(flights: todayFlights)),
                      const SizedBox(width: 24),
                      Expanded(child: _ReservationsListCard(reservations: recentReservations)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _FlightsListCard(flights: todayFlights),
                      const SizedBox(height: 24),
                      _ReservationsListCard(reservations: recentReservations),
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

  // Basit para formatlayıcı (1847500 -> 1.847.500)
  String _formatMoney(int amount) {
    return amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}

// --- 1. WIDGET: İSTATİSTİK KARTI ---
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String change;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1), // Tailwind: bg-{color}-50
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24), // Tailwind: text-{color}-600
              ),
              Text(
                change,
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)), // text-gray-600
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }
}

// --- 2. WIDGET: UÇUŞ LİSTESİ KARTI ---
class _FlightsListCard extends StatelessWidget {
  final List<Map<String, String>> flights;

  const _FlightsListCard({required this.flights});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text("Bugünkü Uçuşlar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: flights.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            padding: const EdgeInsets.all(20),
            itemBuilder: (context, index) {
              final flight = flights[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB), // bg-gray-50
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.flight_takeoff, color: Colors.teal.shade700, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(flight['flightNo']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text("${flight['departure']} → ${flight['arrival']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [

                        const SizedBox(height: 4),
                        _StatusBadge(status: flight['status']!),
                      ],
                    )
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

// --- 3. WIDGET: REZERVASYON LİSTESİ KARTI ---
class _ReservationsListCard extends StatelessWidget {
  final List<Map<String, String>> reservations;

  const _ReservationsListCard({required this.reservations});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text("Son Rezervasyonlar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reservations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            padding: const EdgeInsets.all(20),
            itemBuilder: (context, index) {
              final res = reservations[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      radius: 20,
                      child: Text(
                        res['passenger']!.split(' ').map((n) => n[0]).join(''), // İsim Baş harfleri
                        style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(res['passenger']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(res['flightNo']!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(res['date']!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        const SizedBox(height: 4),
                        _StatusBadge(status: res['status']!),
                      ],
                    )
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

// --- 4. YARDIMCI WIDGET: RENKLİ DURUM ETİKETİ (CHIP) ---
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Zamanında':
      case 'Onaylandı':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'Gecikti':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      case 'Bekliyor':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        break;
      default:
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}