import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';

class ParkingLayout extends StatefulWidget {
  final Widget child;

  const ParkingLayout({super.key, required this.child});

  @override
  State<ParkingLayout> createState() => _ParkingLayoutState();
}

class _ParkingLayoutState extends State<ParkingLayout> {
  // Sidebar durumu (Masaüstü için)
  bool _isSidebarOpen = true;

  // React kodundaki varsayılan kullanıcı bilgileri
  final String userEmail = 'park@airportservices.com';
  final String userRole = 'Parking Manager';

  // --- MENÜ LİSTESİ (React kodundan uyarlandı) ---
  final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.dashboard_outlined, // ri-dashboard-line
      'label': 'Dashboard',
      'path': '/parking/dashboard'
    },
    {
      'icon': Icons.directions_car_outlined, // ri-car-line
      'label': 'Araç Giriş/Çıkış',
      'path': '/parking/entry-exit'
    },
    {
      'icon': Icons.local_parking_outlined, // ri-building-line (veya business)
      'label': 'Otopark Listesi',
      'path': '/parking/parking-lots-list'
    },
    {
      'icon': Icons.event_available_outlined, // ri-calendar-check-line
      'label': 'Rezervasyonlar',
      'path': '/parking/reservations'
    },
    {
      'icon': Icons.monetization_on_outlined, // ri-money-dollar-circle-line
      'label': 'Ödemeler',
      'path': '/parking/payments-list'
    },
  ];

  void _handleLogout() async {
    await AuthService().logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ekran genişliği kontrolü (Responsive)
    final isDesktop = MediaQuery.of(context).size.width > 900;

    // Aktif sayfa kontrolü
    final currentPath = GoRouterState.of(context).uri.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // bg-gray-50

      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {
            if (isDesktop) {
              setState(() => _isSidebarOpen = !_isSidebarOpen);
            } else {
              Scaffold.of(context).openDrawer();
            }
          },
        ),
        title: Row(
          children: [
            // Logo Kutusu (Turuncu Gradient)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange], // from-orange-500 to-orange-600
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_parking, color: Colors.white, size: 20), // ri-parking-box-line
            ),
            const SizedBox(width: 12),

            // Başlık
            if (MediaQuery.of(context).size.width > 400)
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Otopark Yönetimi", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("Parking Panel", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
          ],
        ),
        actions: [
          // Bildirim İkonu
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.grey),
                Positioned(
                  right: 0, top: 0,
                  child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                )
              ],
            ),
            onPressed: () {},
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (isDesktop) ...[
                  Container(width: 1, height: 24, color: Colors.grey.shade300),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(userEmail, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500)),
                      Text(userRole, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(width: 12),
                ],

                // Çıkış Butonu
                InkWell(
                  onTap: _handleLogout,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.logout, color: Colors.grey.shade700, size: 20),
                  ),
                ),
              ],
            ),
          )
        ],
      ),

      // --- DRAWER (MOBİL) ---
      drawer: !isDesktop
          ? Drawer(
        backgroundColor: Colors.white,
        child: _buildMenuContent(currentPath),
      )
          : null,

      // --- BODY ---
      body: Row(
        children: [
          // --- SIDEBAR (MASAÜSTÜ) ---
          if (isDesktop)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isSidebarOpen ? 260 : 0,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Colors.black12)),
              ),
              child: _isSidebarOpen
                  ? _buildMenuContent(currentPath)
                  : const SizedBox(),
            ),

          // --- CONTENT ---
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }

  // Menü Listesi
  Widget _buildMenuContent(String currentPath) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: _menuItems.map((item) {
              final isActive = currentPath == item['path'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      context.go(item['path']);
                      if (Scaffold.of(context).isDrawerOpen) {
                        Navigator.pop(context);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        // React: bg-orange-50 text-orange-700
                        color: isActive ? Colors.orange.shade50 : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                              item['icon'],
                              size: 22,
                              color: isActive ? Colors.orange.shade700 : Colors.grey.shade700
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item['label'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                              color: isActive ? Colors.orange.shade700 : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}