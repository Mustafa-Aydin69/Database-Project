import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentsListScreen extends StatefulWidget {
  const PaymentsListScreen({super.key});

  @override
  State<PaymentsListScreen> createState() => _PaymentsListScreenState();
}

class _PaymentsListScreenState extends State<PaymentsListScreen> {
  // --- STATE ---
  String _searchTerm = "";
  String _filterStatus = "all";
  Map<String, dynamic>? _selectedPayment;

  // --- MOCK DATA ---
  final List<Map<String, dynamic>> _payments = [
    {
      'id': '1',
      'paymentId': 'PAY-2024-001',
      'plate': '34 ABC 123',
      'vehicleType': 'Otomobil',
      'ownerName': 'Ahmet Yılmaz',
      'entryTime': '2024-01-15 08:30',
      'exitTime': '2024-01-15 14:30',
      'duration': '6 saat',
      'amount': 90.0,
      'paymentMethod': 'Kredi Kartı',
      'status': 'completed',
      'spotNumber': 'A-15',
    },
    {
      'id': '2',
      'paymentId': 'PAY-2024-002',
      'plate': '06 XYZ 789',
      'vehicleType': 'SUV',
      'ownerName': 'Ayşe Demir',
      'entryTime': '2024-01-15 09:15',
      'exitTime': '2024-01-15 15:45',
      'duration': '6 saat 30 dakika',
      'amount': 97.0,
      'paymentMethod': 'Nakit',
      'status': 'completed',
      'spotNumber': 'B-23',
    },
    {
      'id': '3',
      'paymentId': 'PAY-2024-003',
      'plate': '35 DEF 456',
      'vehicleType': 'Minivan',
      'ownerName': 'Mehmet Kaya',
      'entryTime': '2024-01-15 10:00',
      'exitTime': '2024-01-15 12:30',
      'duration': '2 saat 30 dakika',
      'amount': 37.0,
      'paymentMethod': 'Mobil Ödeme',
      'status': 'completed',
      'spotNumber': 'C-08',
    },
    {
      'id': '4',
      'paymentId': 'PAY-2024-004',
      'plate': '16 GHI 321',
      'vehicleType': 'Otomobil',
      'ownerName': 'Fatma Şahin',
      'entryTime': '2024-01-15 11:20',
      'exitTime': '2024-01-15 18:50',
      'duration': '7 saat 30 dakika',
      'amount': 112.0,
      'paymentMethod': 'Kredi Kartı',
      'status': 'completed',
      'spotNumber': 'A-42',
    },
    {
      'id': '5',
      'paymentId': 'PAY-2024-005',
      'plate': '41 JKL 654',
      'vehicleType': 'Pickup',
      'ownerName': 'Ali Öztürk',
      'entryTime': '2024-01-15 12:45',
      'exitTime': '2024-01-15 16:15',
      'duration': '3 saat 30 dakika',
      'amount': 52.0,
      'paymentMethod': 'Nakit',
      'status': 'completed',
      'spotNumber': 'D-17',
    },
    {
      'id': '6',
      'paymentId': 'PAY-2024-006',
      'plate': '34 MNO 987',
      'vehicleType': 'Otomobil',
      'ownerName': 'Zeynep Arslan',
      'entryTime': '2024-01-15 07:00',
      'exitTime': '2024-01-15 19:30',
      'duration': '12 saat 30 dakika',
      'amount': 187.0,
      'paymentMethod': 'Kredi Kartı',
      'status': 'completed',
      'spotNumber': 'B-12',
    },
    {
      'id': '7',
      'paymentId': 'PAY-2024-007',
      'plate': '06 PQR 246',
      'vehicleType': 'SUV',
      'ownerName': 'Hasan Çelik',
      'entryTime': '2024-01-15 06:30',
      'exitTime': '2024-01-15 20:00',
      'duration': '13 saat 30 dakika',
      'amount': 202.0,
      'paymentMethod': 'Mobil Ödeme',
      'status': 'completed',
      'spotNumber': 'C-29',
    },
    {
      'id': '8',
      'paymentId': 'PAY-2024-008',
      'plate': '35 STU 135',
      'vehicleType': 'Otomobil',
      'ownerName': 'Elif Yıldız',
      'entryTime': '2024-01-15 13:00',
      'exitTime': '2024-01-15 14:00',
      'duration': '1 saat',
      'amount': 20.0,
      'paymentMethod': 'Nakit',
      'status': 'completed',
      'spotNumber': 'A-08',
    },
  ];

  // --- FILTERING ---
  List<Map<String, dynamic>> get _filteredPayments {
    return _payments.where((payment) {
      final matchesSearch =
          payment['plate'].toLowerCase().contains(_searchTerm.toLowerCase()) ||
              payment['ownerName'].toLowerCase().contains(_searchTerm.toLowerCase()) ||
              payment['paymentId'].toLowerCase().contains(_searchTerm.toLowerCase());
      final matchesStatus = _filterStatus == 'all' || payment['status'] == _filterStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  // --- STATS ---
  double get _totalRevenue =>
      _filteredPayments.fold(0, (sum, item) => sum + (item['amount'] as double));

  int get _totalPayments => _filteredPayments.length;

  double get _averagePayment =>
      _totalPayments > 0 ? _totalRevenue / _totalPayments : 0;

  // --- HELPERS ---
  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'refunded':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Tamamlandı';
      case 'pending':
        return 'Beklemede';
      case 'refunded':
        return 'İade Edildi';
      default:
        return status;
    }
  }

  void _showDetailModal(Map<String, dynamic> payment) {
    setState(() {
      _selectedPayment = payment;
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Ödeme Detayı"),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow("Ödeme ID", payment['paymentId']),
                _DetailRow("Plaka", payment['plate']),
                _DetailRow("Araç Tipi", payment['vehicleType']),
                _DetailRow("Araç Sahibi", payment['ownerName']),
                _DetailRow("Park Yeri", payment['spotNumber']),
                const Divider(),
                _DetailRow("Giriş Saati", payment['entryTime']),
                _DetailRow("Çıkış Saati", payment['exitTime']),
                _DetailRow("Kalış Süresi", payment['duration']),
                const Divider(),
                _DetailRow("Ödeme Yöntemi", payment['paymentMethod']),
                _DetailRow("Durum", _getStatusLabel(payment['status']),
                    color: _getStatusColor(payment['status']), isBold: true),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Toplam Tutar:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("${payment['amount']} ₺",
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange)),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text("Kapat"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPayments;
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            const Text("Ödemeler",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 4),
            const Text("Tüm ödeme işlemlerini görüntüleyin ve yönetin",
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            // --- STATS CARDS ---
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 900 ? 3 : 1;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.5,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StatCard(
                      label: "Toplam Gelir",
                      value: currencyFormat.format(_totalRevenue),
                      icon: Icons.monetization_on_outlined,
                      color: Colors.orange,
                    ),
                    _StatCard(
                      label: "Toplam İşlem",
                      value: "$_totalPayments",
                      icon: Icons.receipt_long,
                      color: Colors.green,
                    ),
                    _StatCard(
                      label: "Ortalama Ödeme",
                      value: currencyFormat.format(_averagePayment),
                      icon: Icons.show_chart,
                      color: Colors.teal,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // --- FILTERS ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
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
                            hintText: "Plaka, isim veya ödeme ID ile ara...",
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: OutlineInputBorder(),
                            contentPadding:
                            EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                      SizedBox(
                          width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
                      SizedBox(
                        width: isMobile ? double.infinity : 200,
                        child: DropdownButtonFormField<String>(
                          value: _filterStatus,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding:
                            EdgeInsets.symmetric(horizontal: 12),
                          ),
                          items: const [
                            DropdownMenuItem(value: "all", child: Text("Tüm Durumlar")),
                            DropdownMenuItem(
                                value: "completed", child: Text("Tamamlandı")),
                            DropdownMenuItem(
                                value: "pending", child: Text("Beklemede")),
                            DropdownMenuItem(
                                value: "refunded", child: Text("İade Edildi")),
                          ],
                          onChanged: (val) =>
                              setState(() => _filterStatus = val!),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // --- PAYMENTS LIST ---
            if (filtered.isEmpty)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text("Ödeme bulunamadı.")))
            else
              LayoutBuilder(
                builder: (context, constraints) {
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
                      childAspectRatio: 1.6,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _PaymentCard(
                        payment: filtered[index],
                        onTap: () => _showDetailModal(filtered[index]),
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

// --- WIDGETS ---

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.label,
        required this.value,
        required this.icon,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 28),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  final VoidCallback onTap;

  const _PaymentCard({required this.payment, required this.onTap});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'refunded':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Tamamlandı';
      case 'pending':
        return 'Beklemede';
      case 'refunded':
        return 'İade Edildi';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(payment['status']);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)
          ],
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
                      Text(payment['plate'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(payment['paymentId'],
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(_getStatusLabel(payment['status']),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor)),
                ),
              ],
            ),
            const Divider(),
            _InfoRow(label: "Sahibi", value: payment['ownerName']),
            _InfoRow(label: "Yöntem", value: payment['paymentMethod']),
            _InfoRow(label: "Tarih", value: payment['exitTime'].split(" ")[0]),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${payment['amount']} ₺",
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange)),
                const Icon(Icons.arrow_forward,
                    size: 16, color: Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value,
              style:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;

  const _DetailRow(this.label, this.value,
      {this.isBold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? Colors.black87)),
        ],
      ),
    );
  }
}