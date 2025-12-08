import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ReservationDetailScreen extends StatefulWidget {
  final String reservationId;

  const ReservationDetailScreen({super.key, required this.reservationId});

  @override
  State<ReservationDetailScreen> createState() => _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  // --- MOCK DATA (API Yerine) ---
  late Map<String, dynamic> _reservation;

  @override
  void initState() {
    super.initState();
    // Gerçek uygulamada burada widget.reservationId ile API isteği atılır.
    _reservation = {
      'reservationID': int.tryParse(widget.reservationId) ?? 12345,
      'userName': 'Ahmet Yılmaz',
      'userEmail': 'ahmet.yilmaz@email.com',
      'userPhone': '+90 532 123 4567',
      'flight': 'TK101 - IST → AYT',
      'flightNumber': 'TK101',
      'departure': 'İstanbul Havalimanı (IST)',
      'arrival': 'Antalya Havalimanı (AYT)',
      'departureTime': '2024-01-15T14:30:00',
      'arrivalTime': '2024-01-15T16:15:00',
      'reservationDate': '2024-01-10T14:30:00',
      'status': 'Active',
      'totalAmount': 2550.0,
      'paymentMethod': 'Kredi Kartı',
      'bookingReference': 'TK-2024-001234',
      'passengers': [
        {'passengerID': 1, 'firstName': 'Ahmet', 'lastName': 'Yılmaz', 'seatNumber': '12A', 'ticketNumber': 'TK-001234-1', 'class': 'Economy'},
        {'passengerID': 2, 'firstName': 'Ayşe', 'lastName': 'Yılmaz', 'seatNumber': '12B', 'ticketNumber': 'TK-001234-2', 'class': 'Economy'},
      ],
    };
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active': return Colors.blue;
      case 'Completed': return Colors.green;
      case 'Cancelled': return Colors.red;
      case 'Pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(_reservation['status']);
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final dateFormat = DateFormat('dd MMMM yyyy', 'tr_TR');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Rezervasyon Detayı"),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(), // Geri Dön
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)
            ),
            child: Text(
                _reservation['status'],
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Responsive Layout: Geniş ekranda yan yana (2/3 + 1/3), mobilde alt alta
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  // Masaüstü Görünümü (2 Kolon)
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sol Kolon (Uçuş ve Yolcular) - Flex 2
                      Expanded(flex: 2, child: _buildLeftColumn(dateFormat, timeFormat)),
                      const SizedBox(width: 24),
                      // Sağ Kolon (Müşteri, Ödeme, İşlemler) - Flex 1
                      Expanded(flex: 1, child: _buildRightColumn(currencyFormat)),
                    ],
                  );
                } else {
                  // Mobil Görünümü (Tek Kolon)
                  return Column(
                    children: [
                      _buildLeftColumn(dateFormat, timeFormat),
                      const SizedBox(height: 24),
                      _buildRightColumn(currencyFormat),
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

  // --- SOL KOLON WIDGETLARI ---
  Widget _buildLeftColumn(DateFormat dateFormat, DateFormat timeFormat) {
    return Column(
      children: [
        // 1. UÇUŞ BİLGİLERİ KARTI
        _DetailCard(
          title: "Uçuş Bilgileri",
          icon: Icons.flight_takeoff,
          iconColor: Colors.teal,
          child: Column(
            children: [
              // Kalkış - Uçak - Varış
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Kalkış", style: TextStyle(color: Colors.grey, fontSize: 13)),
                        Text(_reservation['departure'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          timeFormat.format(DateTime.parse(_reservation['departureTime'])),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                        Text(dateFormat.format(DateTime.parse(_reservation['departureTime'])), style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const Icon(Icons.airplanemode_active, size: 32, color: Colors.grey),
                      Text(_reservation['flightNumber'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Varış", style: TextStyle(color: Colors.grey, fontSize: 13)),
                        Text(_reservation['arrival'], style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                        Text(
                          timeFormat.format(DateTime.parse(_reservation['arrivalTime'])),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                        Text(dateFormat.format(DateTime.parse(_reservation['arrivalTime'])), style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
              // Alt Bilgiler
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoItem(label: "Rezervasyon Kodu", value: _reservation['bookingReference']),
                  _InfoItem(
                    label: "Rezervasyon Tarihi",
                    value: dateFormat.format(DateTime.parse(_reservation['reservationDate'])),
                    alignRight: true,
                  ),
                ],
              )
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 2. YOLCU BİLGİLERİ KARTI
        _DetailCard(
          title: "Yolcu Bilgileri",
          icon: Icons.group,
          iconColor: Colors.teal,
          child: Column(
            children: (_reservation['passengers'] as List).map((passenger) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${passenger['firstName']} ${passenger['lastName']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(4)),
                          child: Text(passenger['class'], style: TextStyle(fontSize: 11, color: Colors.teal.shade700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _InfoItem(label: "Koltuk No", value: passenger['seatNumber']),
                        _InfoItem(label: "Bilet No", value: passenger['ticketNumber'], alignRight: true),
                      ],
                    )
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // --- SAĞ KOLON WIDGETLARI ---
  Widget _buildRightColumn(NumberFormat currencyFormat) {
    return Column(
      children: [
        // 1. MÜŞTERİ BİLGİLERİ
        _DetailCard(
          title: "Müşteri Bilgileri",
          icon: Icons.person,
          iconColor: Colors.teal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoItem(label: "Ad Soyad", value: _reservation['userName']),
              const SizedBox(height: 12),
              _InfoItem(label: "E-posta", value: _reservation['userEmail']),
              const SizedBox(height: 12),
              _InfoItem(label: "Telefon", value: _reservation['userPhone']),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 2. ÖDEME BİLGİLERİ
        _DetailCard(
          title: "Ödeme Bilgileri",
          icon: Icons.payment,
          iconColor: Colors.teal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoItem(label: "Ödeme Yöntemi", value: _reservation['paymentMethod']),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Yolcu Sayısı", style: TextStyle(color: Colors.grey)),
                  Text("${(_reservation['passengers'] as List).length}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Toplam Tutar", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    currencyFormat.format(_reservation['totalAmount']),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 3. İŞLEMLER
        _DetailCard(
          title: "İşlemler",
          icon: Icons.settings,
          iconColor: Colors.grey, // Nötr renk
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.print),
                  label: const Text("Bilet Yazdır"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.email),
                  label: const Text("E-posta Gönder"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                ),
              ),
              if (_reservation['status'] == 'Active') ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.cancel),
                    label: const Text("Rezervasyonu İptal Et"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  ),
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }
}

// --- YARDIMCI WIDGETLAR ---

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _DetailCard({required this.title, required this.icon, required this.iconColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final bool alignRight;

  const _InfoItem({required this.label, required this.value, this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}