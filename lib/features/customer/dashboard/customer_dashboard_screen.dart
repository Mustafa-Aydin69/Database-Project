import 'package:flutter/material.dart';

class CustomerDashboardScreen extends StatelessWidget {
  const CustomerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            const Text(
              "Müşteri Paneli",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              "Uçuş ve otopark rezervasyonlarınızı yönetin",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),

            // --- QUICK ACTIONS ---
            const Text(
              "Hızlı İşlemler",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _ActionCard(
                      icon: Icons.flight_takeoff,
                      title: "Uçuş Rezervasyonu",
                      subtitle: "Yeni uçuş rezervasyonu yap",
                      color: Colors.blue,
                      onTap: () {
                        // TODO: Uçuş rezervasyonu sayfasına yönlendir
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Uçuş rezervasyonu özelliği yakında eklenecek")),
                        );
                      },
                    ),
                    _ActionCard(
                      icon: Icons.local_parking,
                      title: "Otopark Rezervasyonu",
                      subtitle: "Otopark yeri rezerve et",
                      color: Colors.orange,
                      onTap: () {
                        // TODO: Otopark rezervasyonu sayfasına yönlendir
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Otopark rezervasyonu özelliği yakında eklenecek")),
                        );
                      },
                    ),
                    _ActionCard(
                      icon: Icons.receipt_long,
                      title: "Rezervasyonlarım",
                      subtitle: "Mevcut rezervasyonlarınızı görüntüle",
                      color: Colors.teal,
                      onTap: () {
                        // TODO: Rezervasyonlar sayfasına yönlendir
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Rezervasyonlar özelliği yakında eklenecek")),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // --- RECENT RESERVATIONS ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Son Rezervasyonlarım",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            "Henüz rezervasyonunuz bulunmuyor",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}







