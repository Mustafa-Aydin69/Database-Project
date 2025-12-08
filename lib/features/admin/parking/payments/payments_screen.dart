import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  // --- STATE ---
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  String _searchTerm = "";
  String _filterMethod = "";
  String _dateFilter = ""; // YYYY-MM-DD

  // Sabit Listeler
  final List<String> _paymentMethods = ['Kredi Kartı', 'Nakit', 'Mobil Ödeme', 'Banka Transferi'];

  // --- MOCK VERİLER ---
  List<Map<String, dynamic>> _payments = [
    {
      'parkingPaymentID': 1, 'userName': 'Mehmet Kaya', 'plateNumber': '06 XYZ 456',
      'spotNumber': 'B-001', 'amount': 156.00, 'paymentMethod': 'Kredi Kartı',
      'paymentTime': '2024-01-15T14:30:00', 'duration': 28
    },
    {
      'parkingPaymentID': 2, 'userName': 'Ahmet Yılmaz', 'plateNumber': '34 MN 789',
      'spotNumber': 'B-002', 'amount': 42.00, 'paymentMethod': 'Nakit',
      'paymentTime': '2024-01-13T18:00:00', 'duration': 6
    },
    {
      'parkingPaymentID': 3, 'userName': 'Fatma Çelik', 'plateNumber': '35 GHI 654',
      'spotNumber': 'A-005', 'amount': 210.00, 'paymentMethod': 'Kredi Kartı',
      'paymentTime': '2024-01-14T20:00:00', 'duration': 35
    },
    {
      'parkingPaymentID': 4, 'userName': 'Ali Yıldız', 'plateNumber': '16 JKL 987',
      'spotNumber': 'C-003', 'amount': 84.00, 'paymentMethod': 'Mobil Ödeme',
      'paymentTime': '2024-01-15T10:15:00', 'duration': 12
    },
    // Sayfalama için veri üretelim
    ...List.generate(15, (index) => {
      'parkingPaymentID': 5 + index,
      'userName': 'User ${index + 1}',
      'plateNumber': '34 AA ${100 + index}',
      'spotNumber': 'P-${10 + index}',
      'amount': (50.0 + index * 10),
      'paymentMethod': index % 2 == 0 ? 'Kredi Kartı' : 'Nakit',
      'paymentTime': '2024-01-${16 + index}T12:00:00',
      'duration': 5 + index
    }),
  ];

  // --- FİLTRELEME VE HESAPLAMA ---
  List<Map<String, dynamic>> get _filteredPayments {
    return _payments.where((p) {
      final matchesSearch = p['userName'].toString().toLowerCase().contains(_searchTerm.toLowerCase()) ||
          p['plateNumber'].toString().toLowerCase().contains(_searchTerm.toLowerCase()) ||
          p['spotNumber'].toString().toLowerCase().contains(_searchTerm.toLowerCase());

      final matchesMethod = _filterMethod.isEmpty || p['paymentMethod'] == _filterMethod;
      final matchesDate = _dateFilter.isEmpty || p['paymentTime'].toString().startsWith(_dateFilter);

      return matchesSearch && matchesMethod && matchesDate;
    }).toList();
  }

  double get _totalRevenue => _filteredPayments.fold(0, (sum, item) => sum + (item['amount'] as double));

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2025),
    );
    if (picked != null) {
      setState(() {
        _dateFilter = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPayments;
    final totalPages = (filtered.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = min(startIndex + _itemsPerPage, filtered.length);
    final currentData = filtered.isEmpty ? [] : filtered.sublist(startIndex, endIndex);

    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

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
                Text("Otopark Ödemeleri", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                SizedBox(height: 4),
                Text("Park ücretlerini ve ödeme geçmişini görüntüleyin", style: TextStyle(color: Colors.grey)),
              ],
            ),

            const SizedBox(height: 24),

            // --- İSTATİSTİK KARTLARI ---
            Row(
              children: [
                Expanded(child: _StatCard(label: "Toplam Gelir", value: currencyFormat.format(_totalRevenue), icon: Icons.attach_money, color: Colors.teal)),
                const SizedBox(width: 16),
                Expanded(child: _StatCard(label: "Toplam İşlem", value: "${filtered.length}", icon: Icons.receipt_long, color: Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _StatCard(
                    label: "Ortalama",
                    value: currencyFormat.format(filtered.isEmpty ? 0 : _totalRevenue / filtered.length),
                    icon: Icons.bar_chart,
                    color: Colors.orange)
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- FİLTRELER ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 800;
                  return Flex(
                    direction: isMobile ? Axis.vertical : Axis.horizontal,
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchTerm = val),
                          decoration: const InputDecoration(
                            hintText: "Kullanıcı, plaka veya park yeri ara...",
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
                      SizedBox(
                        width: isMobile ? double.infinity : 200,
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                suffixIcon: _dateFilter.isNotEmpty
                                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _dateFilter = ""))
                                    : const Icon(Icons.calendar_today)
                            ),
                            child: Text(_dateFilter.isEmpty ? "Tarih Seç" : _dateFilter),
                          ),
                        ),
                      ),
                      SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
                      SizedBox(
                        width: isMobile ? double.infinity : 250,
                        child: DropdownButtonFormField<String>(
                          value: _filterMethod.isEmpty ? null : _filterMethod,
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12), hintText: "Tüm Yöntemler"),
                          items: [
                            const DropdownMenuItem(value: "", child: Text("Tüm Yöntemler")),
                            ..._paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                          ],
                          onChanged: (val) => setState(() => _filterMethod = val ?? ""),
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
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Ödeme bulunamadı.")))
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: currentData.length,
                    itemBuilder: (context, index) {
                      return _PaymentCard(payment: currentData[index]);
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

// --- İSTATİSTİK KARTI ---
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

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
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }
}

// --- ÖDEME KARTI ---
class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;

  const _PaymentCard({required this.payment});

  IconData _getMethodIcon(String method) {
    switch (method) {
      case 'Kredi Kartı': return Icons.credit_card;
      case 'Nakit': return Icons.attach_money;
      case 'Mobil Ödeme': return Icons.smartphone;
      case 'Banka Transferi': return Icons.account_balance;
      default: return Icons.wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

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
              Text(payment['userName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
              Text(currencyFormat.format(payment['amount']), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
            ],
          ),

          const Divider(height: 16),

          Row(
            children: [
              const Icon(Icons.directions_car, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(payment['plateNumber'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              const Icon(Icons.local_parking, size: 16, color: Colors.purple),
              const SizedBox(width: 8),
              Text(payment['spotNumber'], style: const TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.timer, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Text("${payment['duration']} saat", style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Icon(_getMethodIcon(payment['paymentMethod']), size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Text(payment['paymentMethod'], style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Text(dateFormat.format(DateTime.parse(payment['paymentTime'])), style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            ],
          ),
        ],
      ),
    );
  }
}