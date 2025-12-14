import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/parking_service.dart';

class PaymentsListScreen extends StatefulWidget {
  const PaymentsListScreen({super.key});

  @override
  State<PaymentsListScreen> createState() => _PaymentsListScreenState();
}

class _PaymentsListScreenState extends State<PaymentsListScreen> {
  // --- STATE ---
  final ParkingService _parkingService = ParkingService();
  bool _isLoadingStats = true;
  bool _isLoadingPayments = true;
  ParkingPaymentStatistics _paymentStats = ParkingPaymentStatistics.empty();
  List<ParkingPayment> _payments = [];
  String _searchTerm = "";
  String _filterStatus = "all";
  ParkingPayment? _selectedPayment;

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
        _parkingService.getPaymentStatistics(),
        _parkingService.getPaymentList(),
      ]);

      final stats = results[0] as ParkingPaymentStatistics?;
      final payments = results[1] as List<ParkingPayment>;

      debugPrint('📥 Statistics loaded: totalRevenue=${stats?.totalRevenue ?? 0}, totalCount=${stats?.totalTransactionCount ?? 0}, average=${stats?.averagePayment ?? 0}');
      debugPrint('📥 Payments loaded: ${payments.length} items');
      if (payments.isNotEmpty) {
        debugPrint('📋 First payment: ${payments[0].paymentId} - ${payments[0].plateNumber} - ${payments[0].status}');
      }

      setState(() {
        _paymentStats = stats ?? ParkingPaymentStatistics.empty();
        _payments = payments;
        _isLoadingStats = false;
        _isLoadingPayments = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading payments: $e');
      setState(() {
        _isLoadingStats = false;
        _isLoadingPayments = false;
      });
    }
  }

  // --- FILTERING ---
  List<ParkingPayment> get _filteredPayments {
    return _payments.where((payment) {
      final matchesSearch =
          payment.plateNumber.toLowerCase().contains(_searchTerm.toLowerCase()) ||
              payment.ownerName.toLowerCase().contains(_searchTerm.toLowerCase()) ||
              payment.paymentId.toLowerCase().contains(_searchTerm.toLowerCase());
      
      // Status mapping: API'den gelen "Tamamlandı"/"Completed", "Bekleyen"/"Pending", "İptal"/"Cancelled" değerlerini filtrele
      final paymentStatusLower = payment.status.toLowerCase().trim();
      final matchesStatus = _filterStatus == 'all' || 
          (_filterStatus == 'completed' && (paymentStatusLower == 'tamamlandı' || paymentStatusLower == 'completed')) ||
          (_filterStatus == 'pending' && (paymentStatusLower == 'bekleyen' || paymentStatusLower == 'pending')) ||
          (_filterStatus == 'cancelled' && (paymentStatusLower == 'iptal' || paymentStatusLower == 'cancelled' || paymentStatusLower == 'canceled'));
      
      return matchesSearch && matchesStatus;
    }).toList();
  }

  // --- STATS (API'den gelen veriler kullanılıyor) ---
  double get _totalRevenue => _paymentStats.totalRevenue;
  int get _totalPayments => _paymentStats.totalTransactionCount;
  double get _averagePayment => _paymentStats.averagePayment;

  // --- HELPERS ---
  /// Status'a göre renk döndürür (API'den gelen Türkçe status değerleri)
  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower == 'tamamlandı' || statusLower == 'completed') {
      return Colors.green;
    } else if (statusLower == 'bekleyen' || statusLower == 'pending') {
      return Colors.orange;
    } else if (statusLower == 'iptal' || statusLower == 'cancelled' || statusLower == 'canceled') {
      return Colors.red;
    }
    return Colors.grey;
  }

  /// Kalış süresini dakikadan okunabilir formata çevir
  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes dk';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '$hours saat';
    }
    return '$hours saat $remainingMinutes dk';
  }

  void _showDetailModal(ParkingPayment payment) {
    setState(() {
      _selectedPayment = payment;
    });
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    
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
                _DetailRow("Ödeme No", payment.paymentId),
                _DetailRow("Plaka", payment.plateNumber),
                _DetailRow("Araç Tipi", payment.vehicleType),
                _DetailRow("Araç Sahibi", payment.ownerName),
                _DetailRow("Park Yeri", payment.spotNumber),
                const Divider(),
                _DetailRow("Giriş Saati", payment.checkInTime),
                _DetailRow("Çıkış Saati", payment.checkOutTime),
                _DetailRow("Kalış Süresi", _formatDuration(payment.stayDurationMinutes)),
                const Divider(),
                _DetailRow("Ödeme Yöntemi", payment.paymentMethod),
                _DetailRow("Durum", payment.status,
                    color: _getStatusColor(payment.status), isBold: true),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Toplam Tutar:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(currencyFormat.format(payment.amount),
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
    
    // Debug: Ödeme sayısını logla
    debugPrint('🔍 Build - Total payments: ${_payments.length}, Filtered: ${filtered.length}');

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
                      value: _isLoadingStats ? '...' : currencyFormat.format(_totalRevenue),
                      icon: Icons.monetization_on_outlined,
                      color: Colors.orange,
                    ),
                    _StatCard(
                      label: "Toplam İşlem",
                      value: _isLoadingStats ? '...' : "$_totalPayments",
                      icon: Icons.receipt_long,
                      color: Colors.green,
                    ),
                    _StatCard(
                      label: "Ortalama Ödeme",
                      value: _isLoadingStats ? '...' : currencyFormat.format(_averagePayment),
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
                                value: "pending", child: Text("Bekleyen")),
                            DropdownMenuItem(
                                value: "cancelled", child: Text("İptal")),
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
            _isLoadingPayments
                ? const Center(
                    child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator()))
                : filtered.isEmpty
                    ? const Center(
                        child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Text("Ödeme bulunamadı.")))
                    : LayoutBuilder(
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
  final ParkingPayment payment;
  final VoidCallback onTap;

  const _PaymentCard({required this.payment, required this.onTap});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Tamamlandı':
        return Colors.green;
      case 'Bekleyen':
        return Colors.orange;
      case 'İptal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(payment.status);
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

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
                      Text(payment.plateNumber,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(payment.paymentId,
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
                  child: Text(payment.status,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor)),
                ),
              ],
            ),
            const Divider(),
            _InfoRow(label: "Sahibi", value: payment.ownerName),
            _InfoRow(label: "Yöntem", value: payment.paymentMethod),
            _InfoRow(label: "Park Yeri", value: payment.spotNumber),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(currencyFormat.format(payment.amount),
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