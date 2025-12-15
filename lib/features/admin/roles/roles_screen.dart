import 'package:flutter/material.dart';
import 'dart:math';
import '../../../core/services/admin_service.dart';
import '../../../core/services/auth_service.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  // --- STATE ---
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  bool _isLoading = true;
  final AdminService _adminService = AdminService();

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _roleNameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // --- VERİLER ---
  List<AdminRole> _roles = [];

  // --- LIFECYCLE ---
  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  @override
  void dispose() {
    _roleNameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // --- VERİ YÜKLEME ---
  Future<void> _loadRoles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final roles = await _adminService.getRoles();
      if (mounted) {
        setState(() {
          _roles = roles;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading roles: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Roller yüklenirken hata oluştu: ${e.toString()}')),
        );
      }
    }
  }

  // --- CRUD İŞLEMLERİ ---

  // Ekleme/Düzenleme Dialogu
  void _showRoleDialog({AdminRole? role}) {
    if (role != null) {
      _roleNameController.text = role.roleName ?? '';
      _descController.text = role.description ?? '';
    } else {
      _roleNameController.clear();
      _descController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(role != null ? 'Rol Düzenle' : 'Yeni Rol'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _roleNameController,
                    decoration: const InputDecoration(
                      labelText: "Rol Adı",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: "Açıklama",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    maxLines: 3,
                    validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
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
            onPressed: role != null ? () async {
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

                  await _adminService.updateRole(
                    roleId: role.id!,
                    roleName: _roleNameController.text.trim(),
                    description: _descController.text.trim(),
                    adminUserId: adminUserId,
                  );

                  if (mounted) {
                    Navigator.of(context, rootNavigator: true).pop(); // Loading dialog'u kapat
                    Navigator.pop(context); // Modal'ı kapat
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rol başarıyla güncellendi.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Rol listesini yenile
                    _loadRoles();
                  }
                } catch (e) {
                  debugPrint('❌ Error updating role: $e');
                  if (mounted) {
                    Navigator.of(context, rootNavigator: true).pop(); // Loading dialog'u kapat
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
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

                  await _adminService.addRole(
                    roleName: _roleNameController.text.trim(),
                    description: _descController.text.trim(),
                    adminUserId: adminUserId,
                  );

                  if (mounted) {
                    Navigator.of(context, rootNavigator: true).pop(); // Loading dialog'u kapat
                    Navigator.pop(context); // Modal'ı kapat
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rol başarıyla eklendi.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Rol listesini yenile
                    _loadRoles();
                  }
                } catch (e) {
                  debugPrint('❌ Error adding role: $e');
                  if (mounted) {
                    Navigator.of(context, rootNavigator: true).pop(); // Loading dialog'u kapat
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(role != null ? "Güncelle" : "Ekle"),
          ),
        ],
      ),
    );
  }

  // Silme İşlemi
  void _deleteRole(int id) async {
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
        content: const Text("Bu rolü silmek istediğinizden emin misiniz?"),
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
      await _adminService.deleteRole(
        roleId: id,
        adminUserId: adminUserId,
      );

      // Loading dialog'u kapat
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rol başarıyla silindi.'),
            backgroundColor: Colors.green,
          ),
        );
        // Rol listesini yenile
        _loadRoles();
      }
    } catch (e) {
      debugPrint('❌ Error deleting role: $e');
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Sayfalama Mantığı
    final totalPages = (_roles.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = min(startIndex + _itemsPerPage, _roles.length);
    final currentData = _roles.isEmpty ? [] : _roles.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Rol Yönetimi", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text("Sistem rollerini yönetin", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showRoleDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Yeni Rol"),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- ROL KARTLARI (GRID) ---
            if (currentData.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Kayıtlı rol bulunamadı.")))
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  // Kullanıcı listesiyle aynı responsive yapı
                  int crossAxisCount = constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.0, // Kart boyutu
                    ),
                    itemCount: currentData.length,
                    itemBuilder: (context, index) {
                      return _RoleCard(
                        role: currentData[index],
                        onEdit: () => _showRoleDialog(role: currentData[index]),
                        onDelete: () => _deleteRole(currentData[index].id ?? 0),
                      );
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

// --- ROL KARTI ---
class _RoleCard extends StatelessWidget {
  final AdminRole role;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoleCard({required this.role, required this.onEdit, required this.onDelete});

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
          // Üst Kısım: ID ve İsim
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                role.roleName ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                child: Text("ID: ${role.id ?? 'N/A'}", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ),
            ],
          ),

          const Divider(height: 16),

          // Orta Kısım: Açıklama
          Expanded(
            child: Text(
              role.description ?? '',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 8),

          // Alt Kısım: Butonlar
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(8),
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
                  borderRadius: BorderRadius.circular(8),
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