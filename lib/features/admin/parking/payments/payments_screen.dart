import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import '../../../../core/services/admin_service.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  // --- STATE ---
  final AdminService _adminService = AdminService();
  bool _isLoadingStats = true;
  bool _isLoadingPayments = true;
  PaymentSummary? _paymentSummary;
  List<ParkingPaymentDetail> _payments = [];
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  String _searchTerm = "";
  String _filterMethod = "";
  String _dateFilter = ""; // YYYY-MM-DD

  // Sabit Listeler
  final List<String> _paymentMethods = ['Kredi Kartı', 'Nakit', 'Mobil Ödeme', 'Banka Transferi'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// API'den tüm verileri yükle (istatistikler ve ödeme listesi)
  Future<void> _loadData() async {
    setState(() {
      _isLoadingStats = true;
      _isLoadingPayments = true;
    });

    try {
      // İstatistikler ve ödeme listesini paralel yükle
      final results = await Future.wait([
        _adminService.getPaymentSummary(),
        _adminService.getParkingPaymentDetails(),
      ]);

      final summary = results[0] as PaymentSummary?;
      final payments = results[1] as List<ParkingPaymentDetail>;

      setState(() {
        _paymentSummary = summary ?? PaymentSummary(totalRevenue: 0, totalTransactionCount: 0, averagePayment: 0);
        _payments = payments;
        _isLoadingStats = false;
        _isLoadingPayments = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading payments: $e');
      setState(() {
        _paymentSummary = PaymentSummary(totalRevenue: 0, totalTransactionCount: 0, averagePayment: 0);
        _isLoadingStats = false;
        _isLoadingPayments = false;
      });
    }
  }

  // --- FİLTRELEME ---
  List<ParkingPaymentDetail> get _filteredPayments {
    return _payments.where((p) {
      final matchesSearch = (p.ownerName?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false) ||
          (p.plateNumber?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false) ||
          (p.spotNumber?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false) ||
          (p.paymentID?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false);

      final matchesMethod = _filterMethod.isEmpty || (p.paymentMethod ?? '').toLowerCase() == _filterMethod.toLowerCase();
      
      // Tarih filtresi - checkOutTime'a göre filtrele
      final matchesDate = _dateFilter.isEmpty || (p.checkOutTime?.toString().startsWith(_dateFilter) ?? false);

      return matchesSearch && matchesMethod && matchesDate;
    }).toList();
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final safeInitialDate = now.isAfter(DateTime(2030, 12, 31))
        ? DateTime(2030, 12, 31)
        : now;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030, 12, 31),
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
      body: (_isLoadingStats || _isLoadingPayments)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                      Expanded(
                        child: _StatCard(
                          label: "Toplam Gelir",
                          value: _isLoadingStats ? '...' : currencyFormat.format(_paymentSummary?.totalRevenue ?? 0),
                          icon: Icons.attach_money,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          label: "Toplam İşlem",
                          value: _isLoadingStats ? '...' : "${_paymentSummary?.totalTransactionCount ?? 0}",
                          icon: Icons.receipt_long,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          label: "Ortalama",
                          value: _isLoadingStats ? '...' : currencyFormat.format(_paymentSummary?.averagePayment ?? 0),
                          icon: Icons.bar_chart,
                          color: Colors.orange,
                        ),
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
  final ParkingPaymentDetail payment;

  const _PaymentCard({required this.payment});

  IconData _getMethodIcon(String? method) {
    if (method == null) return Icons.wallet;
    switch (method.toLowerCase()) {
      case 'kredi kartı':
      case 'credit card':
        return Icons.credit_card;
      case 'nakit':
      case 'cash':
        return Icons.attach_money;
      case 'mobil ödeme':
      case 'mobile payment':
        return Icons.smartphone;
      case 'banka transferi':
      case 'bank transfer':
        return Icons.account_balance;
      default:
        return Icons.wallet;
    }
  }

  String _formatDateTime(String? dateTimeString, DateFormat format) {
    if (dateTimeString == null) return '-';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return format.format(dateTime);
    } catch (e) {
      return dateTimeString;
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
              Expanded(
                child: Text(
                  payment.ownerName ?? 'Bilinmeyen',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                currencyFormat.format(payment.amount),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            ],
          ),

          const Divider(height: 16),

          Row(
            children: [
              const Icon(Icons.directions_car, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(payment.plateNumber ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              const Icon(Icons.local_parking, size: 16, color: Colors.purple),
              const SizedBox(width: 8),
              Text(payment.spotNumber ?? '-', style: const TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.timer, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                "${payment.stayDurationHours ?? 0} saat",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Icon(_getMethodIcon(payment.paymentMethod), size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                payment.paymentMethod ?? '-',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                _formatDateTime(payment.checkOutTime, dateFormat),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
