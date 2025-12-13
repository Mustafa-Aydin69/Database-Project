import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';

class AdminLayout extends StatefulWidget {
  final Widget child;

  const AdminLayout({super.key, required this.child});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  // Sidebar durumu (Masaüstü için)
  bool _isSidebarOpen = true;

  // Açık olan alt menüyü tutar
  String? _openSubmenu;

  // Kullanıcı Bilgisi (AuthService'den çekiyoruz)
  String get userEmail => 'admin@airportservices.com'; // Burası dinamik yapılabilir
  String get userRole => AuthService().currentRole.toString().split('.').last;

  @override
  void initState() {
    super.initState();
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

  void _handleLogout() async {
    await AuthService().logout();
    if (mounted) {
      context.go('/login');
    }
  }

  /// --- DİNAMİK MENÜ LİSTESİ ---
  /// Kullanıcının rolüne göre menüleri filtreler.
  List<Map<String, dynamic>> get _filteredMenuItems {
    final currentRole = AuthService().currentRole;
    if (currentRole == null) return [];

    // TÜM MENÜ YAPISI VE YETKİLERİ
    final List<Map<String, dynamic>> allMenus = [
      {
        'icon': Icons.dashboard,
        'label': 'Dashboard',
        'path': '/admin/dashboard',
        'allowedRoles': [UserRole.admin, UserRole.airportManager, UserRole.flightManager, UserRole.parkingManager]
      },
      {
        'icon': Icons.manage_accounts,
        'label': 'Kullanıcı Yönetimi',
        'allowedRoles': [UserRole.admin, UserRole.airportManager],
        'submenu': [
          {'label': 'Kullanıcılar', 'path': '/admin/users'},
          {'label': 'Roller', 'path': '/admin/roles'},
          {'label': 'Aktivite Logları', 'path': '/admin/activity-log'},
        ],
      },
      {
        'icon': Icons.flight_takeoff,
        'label': 'Uçuş Yönetimi',
        // Flight Manager burayı görebilir ama içindeki her şeyi göremez (aşağıda filtrelenecek)
        'allowedRoles': [UserRole.admin, UserRole.airportManager, UserRole.flightManager],
        'submenu': [
          // Flight Manager sadece bunları görür:
          {'label': 'Havayolları', 'path': '/admin/airlines', 'allowedRoles': [UserRole.admin, UserRole.airportManager, UserRole.flightManager]},
          {'label': 'Havalimanları', 'path': '/admin/airports', 'allowedRoles': [UserRole.admin, UserRole.airportManager, UserRole.flightManager]},
          // Diğerlerini sadece Admin ve Airport Manager görür:
          {'label': 'Uçuş Sınıfları', 'path': '/admin/flight-classes', 'allowedRoles': [UserRole.admin, UserRole.airportManager]},
          {'label': 'Uçaklar', 'path': '/admin/aircrafts', 'allowedRoles': [UserRole.admin, UserRole.airportManager]},
          {'label': 'Uçuşlar', 'path': '/admin/flights', 'allowedRoles': [UserRole.admin, UserRole.airportManager]},
          {'label': 'Koltuklar', 'path': '/admin/seats', 'allowedRoles': [UserRole.admin, UserRole.airportManager]},
          {'label': 'Fiyatlandırma', 'path': '/admin/flight-pricing', 'allowedRoles': [UserRole.admin, UserRole.airportManager]},
          {'label': 'Uçuş Mürettebatı', 'path': '/admin/flight-crew', 'allowedRoles': [UserRole.admin, UserRole.airportManager]},
        ],
      },
      {
        'icon': Icons.confirmation_number,
        'label': 'Rezervasyon & Bilet',
        'allowedRoles': [UserRole.admin, UserRole.airportManager],
        'submenu': [
          {'label': 'Rezervasyonlar', 'path': '/admin/reservations'},
          {'label': 'Yolcular', 'path': '/admin/passengers'},
        ],
      },
      {
        'icon': Icons.people_alt,
        'label': 'Çalışan & Departman',
        'allowedRoles': [UserRole.admin, UserRole.airportManager],
        'submenu': [
          {'label': 'Departmanlar', 'path': '/admin/departments'},
          {'label': 'Çalışanlar', 'path': '/admin/employees'},
        ],
      },
      {
        'icon': Icons.meeting_room,
        'label': 'Havalimanı & Gate',
        'allowedRoles': [UserRole.admin, UserRole.flightManager],
        'submenu': [
          {'label': 'Gate Yönetimi', 'path': '/admin/gates'},
        ],
      },
      {
        'icon': Icons.local_parking,
        'label': 'Otopark Sistemi',
        'allowedRoles': [UserRole.admin, UserRole.parkingManager],
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

    // LİSTEYİ FİLTRELEME MANTIĞI
    List<Map<String, dynamic>> filteredList = [];

    for (var item in allMenus) {
      // 1. Ana menü yetkisi kontrolü
      List<UserRole> parentRoles = item['allowedRoles'] as List<UserRole>;
      if (!parentRoles.contains(currentRole)) continue; // Yetki yoksa atla

      // 2. Alt menü varsa, onları da filtrele
      if (item.containsKey('submenu')) {
        List<Map<String, dynamic>> originalSubmenu = item['submenu'] as List<Map<String, dynamic>>;
        List<Map<String, dynamic>> allowedSubmenu = [];

        for (var subItem in originalSubmenu) {
          // Eğer alt menüde özel yetki tanımlanmışsa kontrol et, yoksa üst menü yetkisini varsay
          if (subItem.containsKey('allowedRoles')) {
            List<UserRole> subRoles = subItem['allowedRoles'] as List<UserRole>;
            if (subRoles.contains(currentRole)) {
              allowedSubmenu.add(subItem);
            }
          } else {
            allowedSubmenu.add(subItem);
          }
        }

        // Eğer alt menüde gösterilecek hiçbir şey kalmadıysa, ana menüyü de gösterme
        if (allowedSubmenu.isNotEmpty) {
          Map<String, dynamic> newItem = Map.from(item);
          newItem['submenu'] = allowedSubmenu;
          filteredList.add(newItem);
        }
      } else {
        // Alt menü yoksa direkt ekle
        filteredList.add(item);
      }
    }

    return filteredList;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final currentPath = GoRouterState.of(context).uri.toString();

    // Filtrelenmiş menüyü al
    final menuItems = _filteredMenuItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
              Scaffold.of(context).openDrawer();
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

      drawer: !isDesktop
          ? Drawer(
        backgroundColor: Colors.white,
        child: _buildSidebarContent(currentPath, menuItems),
      )
          : null,

      body: Row(
        children: [
          if (isDesktop)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isSidebarOpen ? 260 : 0,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Colors.black12)),
              ),
              child: _isSidebarOpen
                  ? _buildSidebarContent(currentPath, menuItems)
                  : const SizedBox(),
            ),
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent(String currentPath, List<Map<String, dynamic>> menuItems) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      children: menuItems.map((item) {
        if (item.containsKey('submenu')) {
          final submenus = item['submenu'] as List<Map<String, dynamic>>; // dynamic yaptık çünkü filtrelenmiş liste
          final isExpanded = _openSubmenu == item['label'];
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
        } else {
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