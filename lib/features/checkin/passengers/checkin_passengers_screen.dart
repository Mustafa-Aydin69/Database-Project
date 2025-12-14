import 'package:flutter/material.dart';
import 'dart:math';
import '../../../core/services/checkin_service.dart';

class CheckInPassengersScreen extends StatefulWidget {
  const CheckInPassengersScreen({super.key});

  @override
  State<CheckInPassengersScreen> createState() => _CheckInPassengersScreenState();
}

class _CheckInPassengersScreenState extends State<CheckInPassengersScreen> {
  // --- STATE ---
  final CheckInService _checkInService = CheckInService();
  bool _isLoading = true;
  List<CheckInPassenger> _passengers = [];
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  String _searchTerm = "";

  @override
  void initState() {
    super.initState();
    _loadPassengers();
  }

  /// API'den yolcu listesini yükle
  Future<void> _loadPassengers() async {
    setState(() {
      _isLoading = true;
    });

    final passengers = await _checkInService.getPassengerDetailList();

    setState(() {
      _passengers = passengers;
      _isLoading = false;
    });
  }

  // --- MOCK VERİLER (KALDIRILDI) ---
  // Artık API'den gelen veriler kullanılıyor

  // --- FİLTRELEME ---
  List<CheckInPassenger> get _filteredPassengers {
    return _passengers.where((p) {
      return p.fullName.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          p.passportNo.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          p.email.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          p.phone.toLowerCase().contains(_searchTerm.toLowerCase());
    }).toList();
  }

  // --- DETAY MODALI ---
  void _showDetailDialog(CheckInPassenger passenger) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Yolcu Detayları"),
            IconButton(onPressed: () => Navigator.pop(dialogContext), icon: const Icon(Icons.close)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(title: "Kişisel Bilgiler", icon: Icons.person),
                const SizedBox(height: 12),
                _InfoGrid(items: [
                  {'label': 'Ad Soyad', 'value': passenger.fullName},
                  {'label': 'Yaş', 'value': passenger.age?.toString() ?? '-'},
                  {'label': 'Cinsiyet', 'value': passenger.gender},
                ]),

                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),

                _SectionHeader(title: "Pasaport Bilgileri", icon: Icons.book),
                const SizedBox(height: 12),
                _InfoGrid(items: [
                  {'label': 'Pasaport No', 'value': passenger.passportNo},
                  {'label': 'Uyruk', 'value': passenger.nationality},
                ]),

                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),

                _SectionHeader(title: "İletişim Bilgileri", icon: Icons.contact_phone),
                const SizedBox(height: 12),
                _InfoGrid(items: [
                  {'label': 'Email', 'value': passenger.email},
                  {'label': 'Telefon', 'value': passenger.phone},
                ]),

                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),

                _SectionHeader(title: "Uçuş Bilgileri", icon: Icons.flight_takeoff),
                const SizedBox(height: 12),
                _InfoGrid(items: [
                  {'label': 'Rezervasyon No', 'value': passenger.reservationNo},
                  {'label': 'Uçuş No', 'value': passenger.flightNo},
                  {'label': 'Rota', 'value': passenger.route},
                  {'label': 'Koltuk No', 'value': passenger.seatNumber},
                  {'label': 'Durum', 'value': passenger.status},
                ]),
              ],
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black87),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Kapat"),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    List<String> parts = name.split(" ");
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[parts.length - 1][0]}".toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : "";
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPassengers;
    final totalPages = (filtered.length / _itemsPerPage).ceil();

    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    if (totalPages == 0) _currentPage = 0;

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
                Text("Yolcu Bilgileri", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                SizedBox(height: 4),
                Text("Yolcu detaylarını görüntüleyin (Sadece Okuma)", style: TextStyle(color: Colors.grey)),
              ],
            ),

            const SizedBox(height: 24),

            // --- ARAMA ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: TextField(
                onChanged: (val) => setState(() => _searchTerm = val),
                decoration: const InputDecoration(
                  hintText: "Yolcu adı, pasaport veya email ara...",
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- KART LİSTESİ ---
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (currentData.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text(
                    _passengers.isEmpty
                        ? "Yolcu bulunamadı."
                        : "Arama kriterlerinize uygun yolcu bulunamadı.",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
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
                      childAspectRatio: 1.8,
                    ),
                    itemCount: currentData.length,
                    itemBuilder: (context, index) {
                      return _PassengerCard(
                        passenger: currentData[index],
                        initials: _getInitials(currentData[index].fullName),
                        onDetail: () => _showDetailDialog(currentData[index]),
                      );
                    },
                  );
                },
              ),

            // --- SAYFALAMA ---
            const SizedBox(height: 20),
            if (totalPages > 1)
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

// --- YOLCU KARTI ---
class _PassengerCard extends StatelessWidget {
  final CheckInPassenger passenger;
  final String initials;
  final VoidCallback onDetail;

  const _PassengerCard({required this.passenger, required this.initials, required this.onDetail});

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
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.orange.shade100,
                child: Text(initials, style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(passenger.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                    Text(passenger.passportNo, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 16),

          _CardInfoRow(icon: Icons.public, text: passenger.nationality),
          const SizedBox(height: 4),
          _CardInfoRow(icon: Icons.email_outlined, text: passenger.email),
          const SizedBox(height: 4),
          _CardInfoRow(icon: Icons.phone, text: passenger.phone),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onDetail,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade800,
                side: BorderSide(color: Colors.orange.shade200),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text("Detay Görüntüle"),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _CardInfoRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade700), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

// --- MODAL YARDIMCI WIDGETLARI ---
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.orange),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final List<Map<String, String>> items;
  const _InfoGrid({required this.items});
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 12,
      children: items.map((item) {
        return SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['label']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(item['value']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        );
      }).toList(),
    );
  }
}