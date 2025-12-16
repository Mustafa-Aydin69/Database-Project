import 'package:flutter/material.dart';
import 'dart:math';
import '../../../../core/services/admin_service.dart';
import '../../../../core/services/auth_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  // --- STATE DEĞİŞKENLERİ ---
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<AdminUser> _users = [];
  List<AdminRole> _availableRoles = []; // Dinamik rol listesi
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  String _searchTerm = "";
  String _roleFilter = "all"; // all, Admin, Staff, ParkingManager

  // Form Kontrolcüleri (Modal için)
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'Staff';

  @override
  void initState() {
    super.initState();
    _loadData(); // Kullanıcıları ve rolleri paralel yükle
  }

  /// Kullanıcıları ve rolleri yükle
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Paralel olarak kullanıcıları ve rolleri yükle
      final results = await Future.wait([
        _adminService.getUsers(),
        _adminService.getRoles(),
      ]);

      if (mounted) {
        setState(() {
          _users = results[0] as List<AdminUser>;
          _availableRoles = results[1] as List<AdminRole>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veriler yüklenirken hata oluştu: ${e.toString()}')),
        );
      }
    }
  }

  /// API'den kullanıcıları yükle (rol listesi değişmeden sadece kullanıcıları yenile)
  Future<void> _loadUsers() async {
    try {
      final users = await _adminService.getUsers();
      if (mounted) {
        setState(() {
          _users = users;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading users: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kullanıcılar yüklenirken hata oluştu: ${e.toString()}')),
        );
      }
    }
  }

  // --- FİLTRELEME MANTIĞI ---
  List<AdminUser> get _filteredUsers {
    return _users.where((user) {
      final matchesSearch = (user.fullName?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false) ||
          (user.email?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false);
      final matchesRole = _roleFilter == 'all' || (user.roleName ?? '').toLowerCase() == _roleFilter.toLowerCase();
      return matchesSearch && matchesRole;
    }).toList();
  }

  // --- CRUD İŞLEMLERİ ---

  // Modal Açma (Ekleme veya Düzenleme)
  void _showUserDialog({AdminUser? user}) {
    // Formu temizle veya doldur
    if (user != null) {
      _nameController.text = user.fullName ?? '';
      _emailController.text = user.email ?? '';
      _phoneController.text = user.phone ?? '';
      _passwordController.text = ""; // Şifre boş gelir
      // Kullanıcının rolü dropdown'da varsa seç, yoksa ilk rolü seç
      final userRoleName = user.roleName;
      if (userRoleName != null && _availableRoles.any((r) => r.roleName == userRoleName)) {
        _selectedRole = userRoleName;
      } else {
        _selectedRole = _availableRoles.isNotEmpty ? (_availableRoles.first.roleName ?? '') : '';
      }
    } else {
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _passwordController.clear();
      _selectedRole = _availableRoles.isNotEmpty ? (_availableRoles.first.roleName ?? '') : '';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(user != null ? 'Kullanıcı Düzenle' : 'Yeni Kullanıcı'),
        content: SizedBox(
          width: 400, // Modal genişliği
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Ad Soyad", border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: "Telefon", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRole.isNotEmpty ? _selectedRole : null,
                    decoration: const InputDecoration(labelText: "Rol", border: OutlineInputBorder()),
                    items: _availableRoles.map((role) {
                      return DropdownMenuItem(
                        value: role.roleName ?? '',
                        child: Text(role.roleName ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedRole = val ?? ''),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: user != null ? "Şifre (Boş bırakılırsa değişmez)" : "Şifre",
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: true,
                    // Yeni kullanıcı eklerken şifre zorunlu, düzenlerken değil
                    validator: (v) => (user == null && v!.isEmpty) ? "Şifre gerekli" : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: user != null ? () async {
              if (_formKey.currentState!.validate()) {
                // Loading dialog göster
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  final adminUserId = AuthService().currentUserId;
                  if (adminUserId == null) {
                    if (mounted) {
                      Navigator.of(context, rootNavigator: true).pop(); // Loading dialog'u kapat
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kullanıcı ID alınamadı. Lütfen tekrar giriş yapın.')),
                      );
                    }
                    return;
                  }

                  final success = await _adminService.updateUser(
                    userId: user.id!,
                    fullName: _nameController.text.trim(),
                    email: _emailController.text.trim(),
                    phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
                    roleName: _selectedRole,
                    password: _passwordController.text.trim().isEmpty ? null : _passwordController.text.trim(),
                    adminUserId: adminUserId,
                  );

                  if (mounted) {
                    Navigator.of(context, rootNavigator: true).pop(); // Loading dialog'u kapat

                    if (success) {
                      Navigator.pop(context); // Modal'ı kapat
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kullanıcı başarıyla güncellendi.')),
                      );
                      // Kullanıcı listesini yenile
                      _loadUsers();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kullanıcı güncellenirken bir hata oluştu.')),
                      );
                    }
                  }
                } catch (e) {
                  debugPrint('❌ Error updating user: $e');
                  if (mounted) {
                    Navigator.of(context, rootNavigator: true).pop(); // Loading dialog'u kapat
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hata: ${e.toString()}')),
                    );
                  }
                }
              }
            } : () async {
              if (_formKey.currentState!.validate()) {
                // Loading dialog göster
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  final currentUserId = AuthService().currentUserId;
                  if (currentUserId == null) {
                    if (mounted) {
                      Navigator.of(context, rootNavigator: true).pop(); // Loading dialog'u kapat
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kullanıcı ID alınamadı. Lütfen tekrar giriş yapın.')),
                      );
                    }
                    return;
                  }

                  final result = await _adminService.addUser(
                    fullName: _nameController.text.trim(),
                    email: _emailController.text.trim(),
                    phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
                    password: _passwordController.text.trim(),
                    roleName: _selectedRole,
                    currentUserId: currentUserId,
                  );

                  if (mounted) {
                    Navigator.of(context, rootNavigator: true).pop(); // Loading dialog'u kapat

                    if (result['success'] == true) {
                      Navigator.pop(context); // Modal'ı kapat
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kullanıcı başarıyla eklendi.')),
                      );
                      // Kullanıcı listesini yenile
                      _loadUsers();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result['message'] ?? 'Kullanıcı eklenirken bir hata oluştu.')),
                      );
                    }
                  }
                } catch (e) {
                  debugPrint('❌ Error adding user: $e');
                  if (mounted) {
                    Navigator.of(context, rootNavigator: true).pop(); // Loading dialog'u kapat
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hata: ${e.toString()}')),
                    );
                  }
                }
              }
            },
            child: Text(user != null ? "Güncelle" : "Ekle"),
          ),
        ],
      ),
    );
  }

  // Silme İşlemi
  void _deleteUser(int id) async {
    final adminUserId = AuthService().currentUserId;
    if (adminUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı ID alınamadı. Lütfen tekrar giriş yapın.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Onay modalı göster
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Bu kullanıcıyı silmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return; // Kullanıcı iptal etti
    }

    // Loading dialog göster
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (loadingContext) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final success = await _adminService.deleteUser(
        deletedUserId: id,
        adminUserId: adminUserId,
      );

      // Loading dialog'u kapat
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kullanıcı başarıyla silindi.'),
              backgroundColor: Colors.green,
            ),
          );
          // Kullanıcı listesini yenile
          _loadUsers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kullanıcı silinirken bir hata oluştu.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error deleting user: $e');
      // Loading dialog'u kapat
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sayfalama Verisi Hazırlığı
    final filtered = _filteredUsers;
    final totalPages = (filtered.length / _itemsPerPage).ceil();
    // Sayfa sınırı kontrolü (filtreleme sonrası sayfa sayısı azalabilir)
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;

    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = min(startIndex + _itemsPerPage, filtered.length);
    final currentData = filtered.isEmpty ? [] : filtered.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. HEADER KISMI ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Kullanıcı Yönetimi", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                          SizedBox(height: 4),
                          Text("Sistem kullanıcılarını yönetin", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showUserDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text("Yeni Kullanıcı"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- 2. ARAMA VE FİLTRE KARTI ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Mobilde alt alta, masaüstünde yan yana
                        bool isMobile = constraints.maxWidth < 600;

                        return Flex(
                          direction: isMobile ? Axis.vertical : Axis.horizontal,
                          children: [
                            // Arama Kutusu
                            Expanded(
                              child: TextField(
                                onChanged: (val) => setState(() => _searchTerm = val),
                                decoration: InputDecoration(
                                  hintText: "İsim veya email ile ara...",
                                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                ),
                              ),
                            ),

                            // --- ARAYA BOŞLUK EKLEDİK ---
                            SizedBox(
                              width: isMobile ? 0 : 16, // Yan yanayken genişlik ver
                              height: isMobile ? 16 : 0, // Alt altayken yükseklik ver
                            ),

                            // Rol Filtresi
                            SizedBox(
                              width: isMobile ? double.infinity : 200,
                              child: DropdownButtonFormField<String>(
                                value: _roleFilter,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                ),
                                items: [
                                  const DropdownMenuItem(value: 'all', child: Text("Tüm Roller")),
                                  ..._availableRoles.map((role) {
                                    return DropdownMenuItem(
                                      value: role.roleName ?? '',
                                      child: Text(role.roleName ?? ''),
                                    );
                                  }),
                                ],
                                onChanged: (val) => setState(() => _roleFilter = val!),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- 3. KULLANICI LİSTESİ (KART GÖRÜNÜMÜ) ---
                  if (currentData.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Kullanıcı bulunamadı.")))
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
                            childAspectRatio: 1.8, // Kartların en/boy oranı
                          ),
                          itemCount: currentData.length,
                          itemBuilder: (context, index) {
                            return _UserCard(
                              user: currentData[index],
                              onEdit: () => _showUserDialog(user: currentData[index]),
                              onDelete: () => _deleteUser(currentData[index].id ?? 0),
                            );
                          },
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // --- 4. SAYFALAMA ---
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

// --- USER CARD WIDGET ---
class _UserCard extends StatelessWidget {
  final AdminUser user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({required this.user, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    Color roleColor;
    Color roleBgColor;

    switch (user.roleName) {
      case 'Admin':
        roleColor = Colors.teal.shade700;
        roleBgColor = Colors.teal.shade50;
        break;
      case 'ParkingManager':
        roleColor = Colors.indigo.shade700;
        roleBgColor = Colors.indigo.shade50;
        break;
      default: // Staff
        roleColor = Colors.grey.shade700;
        roleBgColor = Colors.grey.shade100;
    }

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
          // Üst Kısım: İsim ve Rol
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName ?? 'Bilinmeyen',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "ID: ${user.id ?? '-'}",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: roleBgColor, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  user.roleName ?? '-',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: roleColor),
                ),
              ),
            ],
          ),

          const Divider(height: 20),

          // Orta Kısım: İletişim Bilgileri
          Column(
            children: [
              _InfoRow(icon: Icons.email_outlined, text: user.email ?? '-'),
              const SizedBox(height: 8),
              _InfoRow(icon: Icons.phone_outlined, text: user.phone ?? '-'),
            ],
          ),

          const Divider(height: 20),

          // Alt Kısım: Butonlar
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 16, color: Colors.teal.shade700),
                          const SizedBox(width: 4),
                          Text("Düzenle", style: TextStyle(color: Colors.teal.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: Colors.red.shade700),
                          const SizedBox(width: 4),
                          Text("Sil", style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
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
  const _InfoRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
