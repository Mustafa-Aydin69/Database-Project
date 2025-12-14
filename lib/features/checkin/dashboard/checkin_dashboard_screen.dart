import 'package:flutter/material.dart';
import '../../../core/services/checkin_service.dart';

class CheckInDashboardScreen extends StatefulWidget {
  const CheckInDashboardScreen({super.key});

  @override
  State<CheckInDashboardScreen> createState() => _CheckInDashboardScreenState();
}

class _CheckInDashboardScreenState extends State<CheckInDashboardScreen> {
  final CheckInService _checkInService = CheckInService();
  bool _isLoading = true;
  bool _isLoadingCheckIns = true;
  CheckInSummary _summary = CheckInSummary.empty();
  List<LastCompletedCheckIn> _recentCheckIns = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// API'den tüm verileri yükle
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isLoadingCheckIns = true;
    });

    // Özet ve son check-in'leri paralel yükle
    final results = await Future.wait([
      _checkInService.getTodaySummary(),
      _checkInService.getLastCompletedCheckInsToday(),
    ]);

    final summary = results[0] as CheckInSummary?;
    final checkIns = results[1] as List<LastCompletedCheckIn>;

    setState(() {
      _summary = summary ?? CheckInSummary.empty();
      _recentCheckIns = checkIns;
      _isLoading = false;
      _isLoadingCheckIns = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // İstatistik kartları - API'den gelen verilerle dinamik
    final stats = [
      {
        'icon': Icons.confirmation_number_outlined, // ri-ticket-2-line
        'label': 'Bugünkü Check-in',
        'value': _isLoading ? '...' : _summary.todayCheckInCount.toString(),
        'color': Colors.orange.shade700,
        'bgColor': Colors.orange.shade50,
      },
      {
        'icon': Icons.access_time, // ri-time-line
        'label': 'Bekleyen',
        'value': _isLoading ? '...' : _summary.pendingCheckInCount.toString(),
        'color': Colors.amber.shade700,
        'bgColor': Colors.amber.shade50,
      },
      {
        'icon': Icons.check_circle_outline, // ri-checkbox-circle-line
        'label': 'Tamamlanan',
        'value': _isLoading ? '...' : _summary.completedCheckInCount.toString(),
        'color': Colors.green.shade700,
        'bgColor': Colors.green.shade50,
      },
      {
        'icon': Icons.cancel, // ri-flight-takeoff-line
        'label': 'İptal Edilen',
        'value': _isLoading ? '...' : _summary.cancelledCheckInCount.toString(),
        'color': const Color.fromARGB(186, 187, 0, 0),
        'bgColor': Colors.teal.shade50,
      },
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
              "Check-in Dashboard",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              "Günlük check-in işlemlerinizi takip edin",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            // --- İSTATİSTİK KARTLARI (Responsive Grid) ---
            LayoutBuilder(
              builder: (context, constraints) {
                // Genişliğe göre kolon sayısı: Geniş > 1100 (4), Orta > 600 (2), Dar (1)
                int crossAxisCount = constraints.maxWidth > 1100 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.8, // Kartın yatay/dikey oranı
                  ),
                  itemCount: stats.length,
                  itemBuilder: (context, index) {
                    final item = stats[index];
                    return _StatCard(
                      label: item['label'] as String,
                      value: item['value'] as String,
                      icon: item['icon'] as IconData,
                      iconColor: item['color'] as Color,
                      bgColor: item['bgColor'] as Color,
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // --- YENİLE BUTONU (Opsiyonel) ---
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),

            const SizedBox(height: 24),

            // --- SON İŞLEMLER TABLOSU ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("Son Check-in İşlemleri", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  const Divider(height: 1),

                  // Tablo Başlığı (Custom Row)
                  Container(
                    color: Colors.grey.shade50,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: _buildTableRow(
                      context,
                      isHeader: true,
                      col1: "Rezervasyon No",
                      col2: "Yolcu Adı",
                      col3: "Uçuş No",
                      col4: "Kalkış",
                      col5: "Durum",
                      col6: "Saat",
                    ),
                  ),
                  const Divider(height: 1),

                  // Tablo İçeriği - Loading, Hata veya Veri durumları
                  _isLoadingCheckIns
                      ? const Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _recentCheckIns.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Center(
                                child: Text(
                                  'Bugün tamamlanan check-in bulunmamaktadır.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _recentCheckIns.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = _recentCheckIns[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  child: _buildTableRow(
                                    context,
                                    isHeader: false,
                                    col1: item.reservationNo,
                                    col2: item.passengerName,
                                    col3: item.flightNo.toString(),
                                    col4: item.route,
                                    col5: item.status,
                                    col6: item.checkInTime,
                                  ),
                                );
                              },
                            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TABLO SATIRI OLUŞTURUCU (Responsive Gizleme Mantığı) ---
  Widget _buildTableRow(
      BuildContext context, {
        required bool isHeader,
        required String col1,
        required String col2,
        required String col3,
        required String col4,
        required String col5,
        required String col6,
      }) {
    // Ekran genişliği kontrolü (React'teki hidden sm:table-cell mantığı)
    double width = MediaQuery.of(context).size.width;
    bool showCol3 = width > 600; // sm
    bool showCol4 = width > 800; // md
    bool showCol6 = width > 1000; // lg

    TextStyle textStyle = TextStyle(
      fontSize: 13,
      fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
      color: isHeader ? Colors.grey.shade600 : Colors.black87,
    );

    return Row(
      children: [
        Expanded(flex: 2, child: Text(col1, style: isHeader ? textStyle : textStyle.copyWith(fontWeight: FontWeight.w500))), // Rezervasyon
        Expanded(flex: 3, child: Text(col2, style: textStyle)), // Yolcu Adı
        if (showCol3) Expanded(flex: 2, child: Text(col3, style: isHeader ? textStyle : textStyle.copyWith(color: Colors.grey.shade600))), // Uçuş No
        if (showCol4) Expanded(flex: 2, child: Text(col4, style: isHeader ? textStyle : textStyle.copyWith(color: Colors.grey.shade600))), // Kalkış
        Expanded(
          flex: 2,
          child: isHeader
              ? Text(col5, style: textStyle)
              : Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: col5 == 'Tamamlanan' ? Colors.green.shade50 : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                      col5 == 'Tamamlandı' ? Icons.check_circle_outline : Icons.access_time,
                      size: 14,
                      color: col5 == 'Tamamlanan' ? Colors.green.shade700 : Colors.amber.shade700
                  ),
                  const SizedBox(width: 4),
                  Text(
                    col5,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: col5 == 'Tamamlanan' ? Colors.green.shade700 : Colors.amber.shade700
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showCol6) Expanded(flex: 2, child: Text(col6, style: textStyle)), // Saat
      ],
    );
  }
}

// --- İSTATİSTİK KARTI WIDGET ---
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

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
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87)),
        ],
      ),
    );
  }
}