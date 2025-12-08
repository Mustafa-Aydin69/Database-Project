import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CheckInLayout extends StatefulWidget {
  final Widget child;

  const CheckInLayout({super.key, required this.child});

  @override
  State<CheckInLayout> createState() => _CheckInLayoutState();
}

class _CheckInLayoutState extends State<CheckInLayout> {
  // Sidebar durumu (Masaüstü için varsayılan açık)
  bool _isSidebarOpen = true;

  // React kodundaki varsayılan kullanıcı
  final String userEmail = 'mustafa@gmail.com';
  final String userRole = 'Kontuar Görevlisi';

  // --- MENÜ LİSTESİ ---
  final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.dashboard_outlined, // ri-dashboard-line
      'label': 'Dashboard',
      'path': '/checkin/dashboard'
    },
    {
      'icon': Icons.confirmation_number_outlined, // ri-ticket-2-line
      'label': 'Bilet Check-in',
      'path': '/checkin/tickets'
    },
    {
      'icon': Icons.person_outline, // ri-user-line
      'label': 'Yolcu Bilgileri',
      'path': '/checkin/passengers'
    },
  ];

  void _handleLogout() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    // Ekran genişliği kontrolü (Responsive)
    final isDesktop = MediaQuery.of(context).size.width > 900;

    // Aktif sayfa kontrolü
    final currentPath = GoRouterState.of(context).uri.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // bg-gray-50

      // --- APP BAR (TOPBAR) ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.grey.shade200)), // Alt çizgi
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12), // Biraz daha yumuşak köşe
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Icon(Icons.room_service, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            if (MediaQuery.of(context).size.width > 400)
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Check-in Kontuarı", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("Yolcu İşlemleri", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (isDesktop) ...[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(userEmail, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(userRole, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Container(width: 1, height: 24, color: Colors.grey.shade300),
                  const SizedBox(width: 12),
                ],
                InkWell(
                  onTap: _handleLogout,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Icon(Icons.logout, color: Colors.red.shade700, size: 20),
                  ),
                ),
              ],
            ),
          )
        ],
      ),

      // --- DRAWER ---
      drawer: !isDesktop
          ? Drawer(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        child: _buildMenuContent(currentPath),
      )
          : null,

      // --- BODY ---
      body: Row(
        children: [
          if (isDesktop)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isSidebarOpen ? 280 : 0, // Kartlar için biraz daha geniş alan
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB), // Sidebar arka planı
                border: Border(right: BorderSide(color: Colors.grey.shade200)),
              ),
              child: _isSidebarOpen
                  ? _buildMenuContent(currentPath)
                  : const SizedBox(),
            ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  // --- KART GÖRÜNÜMLÜ MENÜ ---
  Widget _buildMenuContent(String currentPath) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16), // Kenarlardan boşluk
            children: _menuItems.map((item) {
              final isActive = currentPath == item['path'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 16), // Kartlar arası boşluk
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      context.go(item['path']);
                      if (Scaffold.of(context).isDrawerOpen) {
                        Navigator.pop(context);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: isActive
                            ? Border.all(color: Colors.orange, width: 2) // Aktifse turuncu çerçeve
                            : Border.all(color: Colors.grey.shade200, width: 1), // Pasifse ince gri çerçeve
                        boxShadow: isActive
                            ? [ // Aktifse turuncu gölge
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                            : [ // Pasifse hafif gri gölge
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          // İkon Kutusu
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.orange.shade50 : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              item['icon'],
                              size: 22,
                              color: isActive ? Colors.orange.shade700 : Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Yazı
                          Text(
                            item['label'],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                              color: isActive ? Colors.orange.shade800 : Colors.grey.shade700,
                            ),
                          ),
                          const Spacer(),
                          // Aktifse sağ tarafta küçük bir işaretçi
                          if (isActive)
                            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.orange.shade700)
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