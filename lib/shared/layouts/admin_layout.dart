import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminLayout extends StatefulWidget {
  final Widget child;

  const AdminLayout({super.key, required this.child});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  // Sidebar durumu (Masaüstü için)
  bool _isSidebarOpen = true;

  // Açık olan alt menüyü tutar (React: openSubmenu)
  String? _openSubmenu;

  // Mock Kullanıcı Bilgisi
  final String userEmail = 'admin@airportservices.com';
  final String userRole = 'Admin';

  @override
  void initState() {
    super.initState();
    // Token kontrolü buraya eklenebilir ama genelde Router'da redirect ile yapılır.
  }

  void _toggleSubmenu(String label) {
    setState(() {
      if (_openSubmenu == label) {
        _openSubmenu = null;
      } else {
        _openSubmenu = label;
      }
    });
  }

  void _handleLogout() {
    // SharedPreferences temizleme işlemleri burada yapılır
    context.go('/login');
  }

  // Menü Verisi
  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard, 'label': 'Dashboard', 'path': '/admin/dashboard'},
    {
      'icon': Icons.manage_accounts,
      'label': 'Kullanıcı Yönetimi',
      'submenu': [
        {'label': 'Kullanıcılar', 'path': '/admin/users'},
        {'label': 'Roller', 'path': '/admin/roles'},
        {'label': 'Aktivite Logları', 'path': '/admin/activity-log'},
      ],
    },
    {
      'icon': Icons.flight_takeoff,
      'label': 'Uçuş Yönetimi',
      'submenu': [
        {'label': 'Havayolları', 'path': '/admin/airlines'},
        {'label': 'Havalimanları', 'path': '/admin/airports'},
        {'label': 'Uçuş Sınıfları', 'path': '/admin/flight-classes'},
        {'label': 'Uçaklar', 'path': '/admin/aircrafts'},
        {'label': 'Uçuşlar', 'path': '/admin/flights'},
        {'label': 'Koltuklar', 'path': '/admin/seats'},
        {'label': 'Fiyatlandırma', 'path': '/admin/flight-pricing'},
        {'label': 'Uçuş Mürettebatı', 'path': '/admin/flight-crew'},
      ],
    },
    {
      'icon': Icons.confirmation_number,
      'label': 'Rezervasyon & Bilet',
      'submenu': [
        {'label': 'Rezervasyonlar', 'path': '/admin/reservations'},
        {'label': 'Yolcular', 'path': '/admin/passengers'},
      ],
    },
    // --- EKLENEN KISIM 1: Çalışan & Departman ---
    {
      'icon': Icons.people_alt, // React: ri-team-line
      'label': 'Çalışan & Departman',
      'submenu': [
        {'label': 'Departmanlar', 'path': '/admin/departments'},
        {'label': 'Çalışanlar', 'path': '/admin/employees'},
      ],
    },
    // --- EKLENEN KISIM 2: Havalimanı & Gate ---
    {
      'icon': Icons.meeting_room, // React: ri-building-line
      'label': 'Havalimanı & Gate',
      'submenu': [
        {'label': 'Gate Yönetimi', 'path': '/admin/gates'},
      ],
    },
    {
      'icon': Icons.local_parking,
      'label': 'Otopark Sistemi',
      'submenu': [
        {'label': 'Araç Tipleri', 'path': '/admin/parking/vehicle-types'},
        {'label': 'Otopark Alanları', 'path': '/admin/parking/lots'},
        {'label': 'Park Yerleri', 'path': '/admin/parking/spots'},
        {'label': 'Kullanıcı Araçları', 'path': '/admin/parking/user-vehicles'},
        {'label': 'Otopark Rezervasyonları', 'path': '/admin/parking/reservations'},
        {'label': 'Ödemeler', 'path': '/admin/parking/payments'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Ekran genişliğini al (Responsive kontrolü için)
    final isDesktop = MediaQuery.of(context).size.width > 900;

    // Geçerli yolu al (Aktif menüyü boyamak için)
    final currentPath = GoRouterState.of(context).uri.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // React: bg-gray-50

      // --- TOPBAR (AppBar) ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {
            if (isDesktop) {
              setState(() => _isSidebarOpen = !_isSidebarOpen);
            } else {
              Scaffold.of(context).openDrawer(); // Mobilde Drawer açar
            }
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.teal, Color(0xFF0D9488)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.flight, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            if (isDesktop)
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("AirportServices", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("Admin Panel", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.black54),
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
                InkWell(
                  onTap: _handleLogout,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.logout, color: Colors.black54, size: 20),
                  ),
                ),
              ],
            ),
          )
        ],
      ),

      // --- DRAWER (Sadece Mobil İçin) ---
      drawer: !isDesktop
          ? Drawer(
        backgroundColor: Colors.white,
        child: _buildSidebarContent(currentPath),
      )
          : null,

      // --- BODY ---
      body: Row(
        children: [
          // --- SIDEBAR (Sadece Masaüstü İçin) ---
          if (isDesktop)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isSidebarOpen ? 260 : 0,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Colors.black12)),
              ),
              child: _isSidebarOpen
                  ? _buildSidebarContent(currentPath)
                  : const SizedBox(), // Kapalıyken boş
            ),

          // --- MAIN CONTENT ---
          Expanded(
            child: widget.child, // Sayfa içeriği burada gösterilir
          ),
        ],
      ),
    );
  }

  // Menü İçeriğini Oluşturan Fonksiyon
  Widget _buildSidebarContent(String currentPath) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      children: _menuItems.map((item) {

        // Eğer alt menüsü varsa (Dropdown)
        if (item.containsKey('submenu')) {
          final submenus = item['submenu'] as List<Map<String, String>>;
          final isExpanded = _openSubmenu == item['label'];

          // Alt menülerden biri aktif mi? (Parent menüyü açık tutmak için)
          final bool isChildActive = submenus.any((sub) => sub['path'] == currentPath);

          return Column(
            children: [
              _SidebarButton(
                icon: item['icon'],
                label: item['label'],
                isActive: isExpanded || isChildActive,
                hasSubmenu: true,
                isExpanded: isExpanded,
                onTap: () => _toggleSubmenu(item['label']),
              ),
              // Alt Menü Listesi (Animasyonlu açılış)
              AnimatedCrossFade(
                firstChild: Container(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(left: 12.0, top: 4),
                  child: Column(
                    children: submenus.map((sub) {
                      return _SidebarButton(
                        label: sub['label']!,
                        isActive: currentPath == sub['path'],
                        isSubItem: true,
                        onTap: () => context.go(sub['path']!),
                      );
                    }).toList(),
                  ),
                ),
                crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          );
        }

        // Tekil Menü Elemanı
        else {
          return _SidebarButton(
            icon: item['icon'],
            label: item['label'],
            isActive: currentPath == item['path'],
            onTap: () => context.go(item['path']),
          );
        }
      }).toList(),
    );
  }
}

// --- YARDIMCI WIDGET: MENÜ BUTONU ---
class _SidebarButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool isActive;
  final bool hasSubmenu;
  final bool isExpanded;
  final bool isSubItem;
  final VoidCallback onTap;

  const _SidebarButton({
    this.icon,
    required this.label,
    required this.isActive,
    this.hasSubmenu = false,
    this.isExpanded = false,
    this.isSubItem = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
                vertical: 10,
                horizontal: isSubItem ? 16 : 12
            ),
            decoration: BoxDecoration(
              color: isActive && !hasSubmenu
                  ? Colors.teal.shade50
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                      icon,
                      size: 20,
                      color: isActive ? Colors.teal : Colors.grey.shade700
                  ),
                  const SizedBox(width: 12),
                ] else if (isSubItem) ...[
                  // Alt menü çizgisi
                  Icon(Icons.remove, size: 12, color: isActive ? Colors.teal : Colors.grey),
                  const SizedBox(width: 8),
                ],

                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive || isExpanded ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? Colors.teal.shade700 : Colors.grey.shade700,
                    ),
                  ),
                ),

                if (hasSubmenu)
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.grey,
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}