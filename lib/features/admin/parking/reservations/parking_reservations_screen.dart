import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class ParkingReservationsScreen extends StatefulWidget {
  const ParkingReservationsScreen({super.key});

  @override
  State<ParkingReservationsScreen> createState() => _ParkingReservationsScreenState();
}

class _ParkingReservationsScreenState extends State<ParkingReservationsScreen> {
  // --- STATE ---
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  String _searchTerm = "";
  String _filterStatus = ""; // "", "Active", "Completed", "Cancelled", "Pending"

  // Sabit Listeler
  final List<String> _statuses = ['Active', 'Completed', 'Cancelled', 'Pending'];

  // --- MOCK VERİLER (React'ten alındı) ---
  List<Map<String, dynamic>> _reservations = [
    {
      'parkingReservationID': 1,
      'userID': 1, 'userName': 'Ahmet Yılmaz', 'userEmail': 'ahmet.yilmaz@email.com',
      'spotID': 1, 'spotNumber': 'A-001',
      'vehicleID': 1, 'plateNumber': '34 ABC 123',
      'checkInTime': '2024-01-15T08:00:00', 'checkOutTime': null,
      'status': 'Active',
    },
    {
      'parkingReservationID': 2,
      'userID': 2, 'userName': 'Mehmet Kaya', 'userEmail': 'mehmet.kaya@email.com',
      'spotID': 4, 'spotNumber': 'B-001',
      'vehicleID': 2, 'plateNumber': '06 XYZ 456',
      'checkInTime': '2024-01-14T10:30:00', 'checkOutTime': '2024-01-15T14:30:00',
      'status': 'Completed',
    },
    {
      'parkingReservationID': 3,
      'userID': 3, 'userName': 'Ayşe Demir', 'userEmail': 'ayse.demir@email.com',
      'spotID': 3, 'spotNumber': 'A-003',
      'vehicleID': 4, 'plateNumber': '35 DEF 321',
      'checkInTime': '2024-01-15T06:00:00', 'checkOutTime': null,
      'status': 'Active',
    },
    {
      'parkingReservationID': 4,
      'userID': 1, 'userName': 'Ahmet Yılmaz', 'userEmail': 'ahmet.yilmaz@email.com',
      'spotID': 5, 'spotNumber': 'B-002',
      'vehicleID': 3, 'plateNumber': '34 MN 789',
      'checkInTime': '2024-01-13T12:00:00', 'checkOutTime': '2024-01-13T18:00:00',
      'status': 'Cancelled',
    },
    // Sayfalama için veri üretelim
    ...List.generate(15, (index) => {
      'parkingReservationID': 5 + index,
      'userID': index % 3 + 1,
      'userName': 'User ${index + 1}',
      'userEmail': 'user${index + 1}@email.com',
      'spotID': index + 10,
      'spotNumber': 'C-${100 + index}',
      'vehicleID': index + 5,
      'plateNumber': '34 TES ${index + 100}',
      'checkInTime': '2024-01-16T09:00:00',
      'checkOutTime': index % 2 == 0 ? null : '2024-01-16T12:00:00',
      'status': index % 2 == 0 ? 'Active' : 'Completed',
    }),
  ];

  // --- FİLTRELEME ---
  List<Map<String, dynamic>> get _filteredReservations {
    return _reservations.where((r) {
      final matchesSearch = r['userName'].toString().toLowerCase().contains(_searchTerm.toLowerCase()) ||
          r['plateNumber'].toString().toLowerCase().contains(_searchTerm.toLowerCase()) ||
          r['spotNumber'].toString().toLowerCase().contains(_searchTerm.toLowerCase());

      final matchesStatus = _filterStatus.isEmpty || r['status'] == _filterStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Sayfalama
    final filtered = _filteredReservations;
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
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Otopark Rezervasyonları", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                SizedBox(height: 4),
                Text("Park yeri rezervasyonlarını görüntüleyin ve yönetin", style: TextStyle(color: Colors.grey)),
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
                            hintText: "Kullanıcı, plaka veya park yeri ara...",
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
                      SizedBox(
                        width: isMobile ? double.infinity : 200,
                        child: DropdownButtonFormField<String>(
                          value: _filterStatus.isEmpty ? null : _filterStatus,
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12), hintText: "Tüm Durumlar"),
                          items: [
                            const DropdownMenuItem(value: "", child: Text("Tüm Durumlar")),
                            ..._statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                          ],
                          onChanged: (val) => setState(() => _filterStatus = val ?? ""),
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
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Rezervasyon bulunamadı.")))
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  // Rezervasyon kartları biraz detaylı, 2-3 sütun olabilir
                  int crossAxisCount = constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.4, // Kart boyutu
                    ),
                    itemCount: currentData.length,
                    itemBuilder: (context, index) {
                      return _ParkingReservationCard(reservation: currentData[index]);
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

// --- OTOPARK REZERVASYON KARTI ---
class _ParkingReservationCard extends StatelessWidget {
  final Map<String, dynamic> reservation;

  const _ParkingReservationCard({required this.reservation});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active': return Colors.blue;
      case 'Completed': return Colors.green;
      case 'Cancelled': return Colors.red;
      case 'Pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _calculateDuration(String checkIn, String? checkOut) {
    if (checkOut == null) return 'Devam ediyor';
    final start = DateTime.parse(checkIn);
    final end = DateTime.parse(checkOut);
    final hours = end.difference(start).inHours;
    return '$hours saat';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(reservation['status']);
    final dateFormat = DateFormat('dd.MM HH:mm');

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reservation['userName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
                    Text(reservation['userEmail'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(reservation['status'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),

          const Divider(height: 16),

          Row(
            children: [
              const Icon(Icons.local_parking, size: 16, color: Colors.purple),
              const SizedBox(width: 8),
              Text(reservation['spotNumber'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              const Icon(Icons.directions_car, size: 16, color: Colors.teal),
              const SizedBox(width: 8),
              Text(reservation['plateNumber'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.login, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Text("Giriş: ${dateFormat.format(DateTime.parse(reservation['checkInTime']))}", style: const TextStyle(fontSize: 12, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.logout, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                  "Çıkış: ${reservation['checkOutTime'] != null ? dateFormat.format(DateTime.parse(reservation['checkOutTime'])) : '-'}",
                  style: const TextStyle(fontSize: 12, color: Colors.black87)
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.timer, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                  "Süre: ${_calculateDuration(reservation['checkInTime'], reservation['checkOutTime'])}",
                  style: const TextStyle(fontSize: 12, color: Colors.black87)
              ),
            ],
          ),
        ],
      ),
    );
  }
}