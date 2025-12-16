import 'package:flutter/material.dart';
import 'dart:math';

class CheckInPassengersScreen extends StatefulWidget {
  const CheckInPassengersScreen({super.key});

  @override
  State<CheckInPassengersScreen> createState() => _CheckInPassengersScreenState();
}

class _CheckInPassengersScreenState extends State<CheckInPassengersScreen> {
  // --- STATE ---
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  String _searchTerm = "";

  // --- MOCK VERİLER ---
  List<Map<String, dynamic>> _passengers = [
    {
      'id': 'P001', 'name': 'Ahmet Yılmaz', 'passport': 'U12345678', 'nationality': 'Türkiye',
      'dateOfBirth': '1985-05-15', 'gender': 'Erkek', 'email': 'ahmet.yilmaz@email.com',
      'phone': '+90 532 123 4567', 'flight': 'TK101 - IST → AYT', 'seat': '12A', 'checkInStatus': 'Bekliyor'
    },
    {
      'id': 'P002', 'name': 'Ayşe Demir', 'passport': 'U23456789', 'nationality': 'Türkiye',
      'dateOfBirth': '1990-08-22', 'gender': 'Kadın', 'email': 'ayse.demir@email.com',
      'phone': '+90 533 234 5678', 'flight': 'TK205 - IST → ADB', 'seat': '8C', 'checkInStatus': 'Tamamlandı'
    },
    {
      'id': 'P003', 'name': 'Mehmet Kaya', 'passport': 'U34567890', 'nationality': 'Türkiye',
      'dateOfBirth': '1978-12-10', 'gender': 'Erkek', 'email': 'mehmet.kaya@email.com',
      'phone': '+90 534 345 6789', 'flight': 'TK301 - IST → ESB', 'seat': '15B', 'checkInStatus': 'Bekliyor'
    },
    {
      'id': 'P004', 'name': 'Fatma Şahin', 'passport': 'U45678901', 'nationality': 'Türkiye',
      'dateOfBirth': '1995-03-18', 'gender': 'Kadın', 'email': 'fatma.sahin@email.com',
      'phone': '+90 535 456 7890', 'flight': 'TK101 - IST → AYT', 'seat': '20D', 'checkInStatus': 'Tamamlandı'
    },
    // Sayfalama için veri üretelim
    ...List.generate(15, (index) => {
      'id': 'P${100 + index}',
      'name': 'Yolcu ${index + 1}',
      'passport': 'X${89000 + index}',
      'nationality': index % 3 == 0 ? 'Almanya' : 'Türkiye',
      'dateOfBirth': '199${index % 9}-01-01',
      'gender': index % 2 == 0 ? 'Erkek' : 'Kadın',
      'email': 'yolcu${index + 1}@mail.com',
      'phone': '+90 555 000 ${1000 + index}',
      'flight': 'TK${100 + (index % 5)} - IST → LHR',
      'seat': '${index + 1}F',
      'checkInStatus': index % 2 == 0 ? 'Bekliyor' : 'Tamamlandı'
    }),
  ];

  // --- FİLTRELEME ---
  List<Map<String, dynamic>> get _filteredPassengers {
    return _passengers.where((p) {
      return p['name'].toString().toLowerCase().contains(_searchTerm.toLowerCase()) ||
          p['passport'].toString().toLowerCase().contains(_searchTerm.toLowerCase()) ||
          p['flight'].toString().toLowerCase().contains(_searchTerm.toLowerCase());
    }).toList();
  }

  // --- DETAY MODALI ---
  void _showDetailDialog(Map<String, dynamic> passenger) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Yolcu Detayları"),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
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
                  {'label': 'Ad Soyad', 'value': passenger['name']},
                  {'label': 'Doğum Tarihi', 'value': passenger['dateOfBirth']},
                  {'label': 'Cinsiyet', 'value': passenger['gender']},
                ]),

                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),

                _SectionHeader(title: "Pasaport Bilgileri", icon: Icons.book),
                const SizedBox(height: 12),
                _InfoGrid(items: [
                  {'label': 'Pasaport No', 'value': passenger['passport']},
                  {'label': 'Uyruk', 'value': passenger['nationality']},
                ]),

                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),

                _SectionHeader(title: "İletişim Bilgileri", icon: Icons.contact_phone),
                const SizedBox(height: 12),
                _InfoGrid(items: [
                  {'label': 'Email', 'value': passenger['email']},
                  {'label': 'Telefon', 'value': passenger['phone']},
                ]),

                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),

                _SectionHeader(title: "Uçuş Bilgileri", icon: Icons.flight_takeoff),
                const SizedBox(height: 12),
                _InfoGrid(items: [
                  {'label': 'Uçuş', 'value': passenger['flight']},
                  {'label': 'Koltuk No', 'value': passenger['seat']},
                  {'label': 'Durum', 'value': passenger['checkInStatus']},
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
              onPressed: () => Navigator.pop(context),
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
            if (currentData.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Yolcu bulunamadı.")))
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
                        initials: _getInitials(currentData[index]['name']),
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
  final Map<String, dynamic> passenger;
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
                    Text(passenger['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                    Text(passenger['passport'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 16),

          _CardInfoRow(icon: Icons.public, text: passenger['nationality']),
          const SizedBox(height: 4),
          _CardInfoRow(icon: Icons.email_outlined, text: passenger['email']),
          const SizedBox(height: 4),
          _CardInfoRow(icon: Icons.phone, text: passenger['phone']),

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