import 'package:flutter/material.dart';
import 'dart:math';
import '../../../core/services/admin_service.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  // --- STATE ---
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<ActivityLog> _logs = [];
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  String _searchTerm = "";
  String _dateFilter = ""; // "YYYY-MM-DD" formatında tutulacak

  @override
  void initState() {
    super.initState();
    _loadActivityLogs();
  }

  /// API'den aktivite loglarını yükle
  Future<void> _loadActivityLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final logs = await _adminService.getActivityLogs();
      debugPrint('📥 Activity logs loaded: ${logs.length} items');
      
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading activity logs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- MOCK VERİLER (KALDIRILDI) ---
  /* final List<Map<String, dynamic>> _logs = [
    {'id': 1, 'userName': 'Ahmet Yılmaz', 'action': 'Kullanıcı Ekleme', 'description': 'Yeni kullanıcı eklendi: ayse.demir@example.com', 'logDate': '2024-01-15 10:30:45'},
    {'id': 2, 'userName': 'Mehmet Kaya', 'action': 'Uçuş Güncelleme', 'description': 'FL001 uçuşu Delayed olarak güncellendi', 'logDate': '2024-01-15 11:15:22'},
    {'id': 3, 'userName': 'Fatma Şahin', 'action': 'Rezervasyon İptali', 'description': 'RES-12345 rezervasyonu iptal edildi', 'logDate': '2024-01-15 12:45:10'},
    {'id': 4, 'userName': 'Ali Öztürk', 'action': 'Otopark Ekleme', 'description': 'Yeni park yeri eklendi: A-89', 'logDate': '2024-01-15 13:20:33'},
    {'id': 5, 'userName': 'Ahmet Yılmaz', 'action': 'Rol Güncelleme', 'description': 'Kullanıcı rolü Staff olarak değiştirildi', 'logDate': '2024-01-15 14:05:18'},
    {'id': 6, 'userName': 'Ayşe Demir', 'action': 'Gate Ekleme', 'description': 'Yeni gate eklendi: Terminal 2 - G15', 'logDate': '2024-01-15 15:30:55'},
    {'id': 7, 'userName': 'Mehmet Kaya', 'action': 'Fiyat Güncelleme', 'description': 'Economy class fiyatı güncellendi', 'logDate': '2024-01-15 16:10:42'},
    {'id': 8, 'userName': 'Fatma Şahin', 'action': 'Çalışan Ekleme', 'description': 'Yeni çalışan eklendi: Zeynep Aydın', 'logDate': '2024-01-15 17:25:11'},
    // Sayfalamayı test etmek için veri çoğaltma
    ...List.generate(15, (index) => {
      'id': 9 + index,
      'userName': 'Sistem',
      'action': 'Otomatik Yedekleme',
      'description': 'Günlük veritabanı yedeği alındı.',
      'logDate': '2024-01-${16 + index} 03:00:00'
    }),
  ]; */

  // --- FİLTRELEME ---
  List<ActivityLog> get _filteredLogs {
    return _logs.where((log) {
      final matchesSearch = (log.userName ?? '').toLowerCase().contains(_searchTerm.toLowerCase()) ||
          (log.action ?? '').toLowerCase().contains(_searchTerm.toLowerCase()) ||
          (log.description ?? '').toLowerCase().contains(_searchTerm.toLowerCase());

      final logDateStr = log.logDate ?? '';
      final matchesDate = _dateFilter.isEmpty || logDateStr.startsWith(_dateFilter);

      return matchesSearch && matchesDate;
    }).toList();
  }

  // Tarih Seçici
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
        // "2024-01-15" formatına çevir
        _dateFilter = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sayfalama Hesaplamaları
    final filtered = _filteredLogs;
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
                Text("Aktivite Logları", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                SizedBox(height: 4),
                Text("Sistem aktivitelerini görüntüleyin", style: TextStyle(color: Colors.grey)),
              ],
            ),

            const SizedBox(height: 24),

            // --- FİLTRELEME KARTI ---
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
                      // Arama Kutusu
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchTerm = val),
                          decoration: InputDecoration(
                            hintText: "Kullanıcı, aksiyon veya açıklama ile ara...",
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          ),
                        ),
                      ),

                      SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),

                      // Tarih Seçici
                      SizedBox(
                        width: isMobile ? double.infinity : 200,
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          borderRadius: BorderRadius.circular(8),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              prefixIcon: const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                              suffixIcon: _dateFilter.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => setState(() => _dateFilter = ""),
                              )
                                  : null,
                            ),
                            child: Text(
                              _dateFilter.isEmpty ? "Tarih Seçin" : _dateFilter,
                              style: TextStyle(color: _dateFilter.isEmpty ? Colors.grey : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // --- LOG KARTLARI (Responsive Grid) ---
            _isLoading
                ? const Center(
                    child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator()))
                : currentData.isEmpty
                    ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Kayıt bulunamadı.")))
                    : LayoutBuilder(
                builder: (context, constraints) {
                  // Loglar genellikle uzun açıklamalı olduğu için 2 sütun ideal
                  int crossAxisCount = constraints.maxWidth > 900 ? 2 : 1;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: constraints.maxWidth > 600 ? 3.0 : 1.8, // Kart boyutu
                    ),
                    itemCount: currentData.length,
                    itemBuilder: (context, index) {
                      return _LogCard(log: currentData[index]);
                    },
                  );
                },
              ),

            const SizedBox(height: 24),

            // --- SAYFALAMA ---
            if (totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text("Sayfa ${_currentPage + 1} / $totalPages"),
                  ),
                  IconButton(
                    onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// --- LOG KARTI ---
class _LogCard extends StatelessWidget {
  final ActivityLog log;
  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
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
          // Üst Kısım: ID ve Etiket
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.history, size: 18, color: Colors.teal.shade700),
                  ),
                  const SizedBox(width: 8),
                  Text("#${log.logId ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  log.action ?? 'N/A',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                ),
              ),
            ],
          ),

          const Divider(height: 16),

          // Orta Kısım: Detaylar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _InfoRow(icon: Icons.person_outline, text: log.userName ?? 'N/A', isBold: true),
                const SizedBox(height: 6),
                _InfoRow(icon: Icons.info_outline, text: log.description ?? 'N/A'),
              ],
            ),
          ),

          const Divider(height: 16),

          // Alt Kısım: Tarih
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                log.logDate ?? 'N/A',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isBold;
  const _InfoRow({required this.icon, required this.text, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isBold ? Colors.black87 : Colors.grey.shade700,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}