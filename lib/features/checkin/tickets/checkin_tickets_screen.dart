import 'package:flutter/material.dart';
import 'dart:math';

class CheckInTicketsScreen extends StatefulWidget {
  const CheckInTicketsScreen({super.key});

  @override
  State<CheckInTicketsScreen> createState() => _CheckInTicketsScreenState();
}

class _CheckInTicketsScreenState extends State<CheckInTicketsScreen> {
  // --- STATE ---
  String _searchTerm = "";
  String _filterStatus = "all"; // 'all', 'Bekliyor', 'Tamamlandı'

  // Modal Kontrolcüleri
  final TextEditingController _passportController = TextEditingController();
  String? _passportError;

  // --- MOCK VERİLER ---
  List<Map<String, dynamic>> _tickets = [
    {
      'id': 'T001',
      'reservationId': 'R12345',
      'passenger': 'Ahmet Yılmaz',
      'passport': '',
      'flight': 'TK101 - IST → AYT',
      'flightDate': '2024-01-15',
      'departureTime': '14:30',
      'seat': '12A',
      'class': 'Economy',
      'checkInStatus': 'Bekliyor',
      'checkInTime': null,
    },
    {
      'id': 'T002',
      'reservationId': 'R12346',
      'passenger': 'Ayşe Demir',
      'passport': 'U23456789',
      'flight': 'TK205 - IST → ADB',
      'flightDate': '2024-01-15',
      'departureTime': '15:45',
      'seat': '8C',
      'class': 'Business',
      'checkInStatus': 'Tamamlandı',
      'checkInTime': '10:45',
    },
    {
      'id': 'T003',
      'reservationId': 'R12347',
      'passenger': 'Mehmet Kaya',
      'passport': '',
      'flight': 'TK301 - IST → ESB',
      'flightDate': '2024-01-15',
      'departureTime': '16:00',
      'seat': '15B',
      'class': 'Economy',
      'checkInStatus': 'Bekliyor',
      'checkInTime': null,
    },
    {
      'id': 'T004',
      'reservationId': 'R12348',
      'passenger': 'Fatma Şahin',
      'passport': 'U45678901',
      'flight': 'TK101 - IST → AYT',
      'flightDate': '2024-01-15',
      'departureTime': '14:30',
      'seat': '20D',
      'class': 'Economy',
      'checkInStatus': 'Tamamlandı',
      'checkInTime': '11:15',
    },
    {
      'id': 'T005',
      'reservationId': 'R12349',
      'passenger': 'Ali Öztürk',
      'passport': '',
      'flight': 'TK205 - IST → ADB',
      'flightDate': '2024-01-15',
      'departureTime': '15:45',
      'seat': '5A',
      'class': 'Business',
      'checkInStatus': 'Bekliyor',
      'checkInTime': null,
    },
    {
      'id': 'T006',
      'reservationId': 'R12350',
      'passenger': 'Zeynep Arslan',
      'passport': '',
      'flight': 'TK401 - IST → DLM',
      'flightDate': '2024-01-15',
      'departureTime': '17:15',
      'seat': '10F',
      'class': 'Economy',
      'checkInStatus': 'Bekliyor',
      'checkInTime': null,
    },
  ];

  // --- FİLTRELEME ---
  List<Map<String, dynamic>> get _filteredTickets {
    return _tickets.where((t) {
      final matchesSearch =
          t['passenger'].toLowerCase().contains(_searchTerm.toLowerCase()) ||
          t['passport'].toLowerCase().contains(_searchTerm.toLowerCase()) ||
          t['flight'].toLowerCase().contains(_searchTerm.toLowerCase()) ||
          t['reservationId'].toLowerCase().contains(_searchTerm.toLowerCase());

      final matchesFilter =
          _filterStatus == 'all' || t['checkInStatus'] == _filterStatus;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  // --- CHECK-IN İŞLEMİ ---
  void _showCheckInDialog(Map<String, dynamic> ticket) {
    _passportController.clear();
    _passportError = null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Pasaport Numarası Girin"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _passportController,
                  decoration: const InputDecoration(
                    labelText: "Pasaport No",
                    hintText: "Örn: U12345678",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    setModalState(() {
                      _passportController.text = val.toUpperCase();
                      _passportController
                          .selection = TextSelection.fromPosition(
                        TextPosition(offset: _passportController.text.length),
                      );
                      _passportError = null;
                    });
                  },
                ),
                if (_passportError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _passportError!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "İptal",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (_passportController.text.trim().isEmpty) {
                    setModalState(
                      () => _passportError =
                          "Pasaport numarası girilmesi zorunludur",
                    );
                    return;
                  }

                  // Check-in Tamamla
                  setState(() {
                    final index = _tickets.indexWhere(
                      (t) => t['id'] == ticket['id'],
                    );
                    if (index != -1) {
                      final now = DateTime.now();
                      _tickets[index] = {
                        ..._tickets[index],
                        'passport': _passportController.text.trim(),
                        'checkInStatus': 'Tamamlandı',
                        'checkInTime':
                            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
                      };
                    }
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Check-in başarıyla tamamlandı."),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text("Onayla"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTickets;

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
                Text(
                  "Bilet Check-in",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Yolcu biletlerini kontrol edin ve check-in yapın",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- FİLTRELER VE ARAMA ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => setState(() => _searchTerm = val),
                    decoration: const InputDecoration(
                      hintText:
                          "Rezervasyon no, yolcu adı veya pasaport ara...",
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterButton(
                          label: "Tümü",
                          isActive: _filterStatus == 'all',
                          onTap: () => setState(() => _filterStatus = 'all'),
                        ),
                        const SizedBox(width: 8),
                        _FilterButton(
                          label: "Bekleyen",
                          isActive: _filterStatus == 'Bekliyor',
                          onTap: () =>
                              setState(() => _filterStatus = 'Bekliyor'),
                        ),
                        const SizedBox(width: 8),
                        _FilterButton(
                          label: "Tamamlanan",
                          isActive: _filterStatus == 'Tamamlandı',
                          onTap: () =>
                              setState(() => _filterStatus = 'Tamamlandı'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- KART LİSTESİ ---
            if (filtered.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text("Kayıt bulunamadı."),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  // Masaüstünde 3, Tablette 2, Mobilde 1 kolon
                  int crossAxisCount = constraints.maxWidth > 1100
                      ? 3
                      : (constraints.maxWidth > 700 ? 2 : 1);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5, // Kart boyutu
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _TicketCard(
                        ticket: filtered[index],
                        onCheckIn: () => _showCheckInDialog(filtered[index]),
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

// --- YARDIMCI WIDGETLAR ---

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.orange : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final VoidCallback onCheckIn;

  const _TicketCard({required this.ticket, required this.onCheckIn});

  @override
  Widget build(BuildContext context) {
    bool isCompleted = ticket['checkInStatus'] == 'Tamamlandı';
    Color statusColor = isCompleted ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Üst Kısım: Yolcu ve ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket['passenger'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      ticket['reservationId'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle : Icons.schedule,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ticket['checkInStatus'],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 16),

          // Orta Kısım: Detaylar
          _InfoRow(icon: Icons.flight_takeoff, text: ticket['flight']),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.calendar_today,
            text: "${ticket['flightDate']} • ${ticket['departureTime']}",
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.event_seat,
            text: "Koltuk: ${ticket['seat']} • ${ticket['class']}",
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.contact_page,
            text: ticket['passport'].toString().isEmpty
                ? "Pasaport girilmedi"
                : ticket['passport'],
          ),

          const SizedBox(height: 12),

          // Alt Kısım: Buton
          if (!isCompleted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.check),
                label: const Text("Check-in Yap"),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  "İşlem Tamamlandı",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
