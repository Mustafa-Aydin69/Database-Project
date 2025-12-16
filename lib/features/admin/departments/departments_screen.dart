import 'package:flutter/material.dart';
import 'dart:math';
import '../../../core/services/admin_service.dart';
import '../../../core/services/auth_service.dart';

class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  // --- STATE ---
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<Department> _departments = [];
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _managerIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  /// API'den departman listesini yükle
  Future<void> _loadDepartments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final departments = await _adminService.getDepartments();
      debugPrint('📥 Departments loaded: ${departments.length} items');
      
      setState(() {
        _departments = departments;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading departments: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- CRUD İŞLEMLERİ ---

  void _showDepartmentDialog({Department? department}) {
    if (department != null) {
      _nameController.text = department.departmentName ?? '';
      _descController.text = department.description ?? '';
      _managerIdController.text = department.departmentManagerId?.toString() ?? '';
    } else {
      _nameController.clear();
      _descController.clear();
      _managerIdController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(department != null ? 'Departman Düzenle' : 'Yeni Departman'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Departman Adı",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: "Açıklama",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                    validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _managerIdController,
                    decoration: const InputDecoration(
                      labelText: "Yönetici ID",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Zorunlu alan";
                      if (int.tryParse(v) == null) return "Geçerli sayı giriniz";
                      return null;
                    },
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
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                if (department != null) {
                  // Güncelleme işlemi
                  final userId = AuthService().currentUserId;
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kullanıcı bilgisi bulunamadı')),
                    );
                    return;
                  }

                  final success = await _adminService.updateDepartment(
                    departmentId: department.departmentId!,
                    departmentName: _nameController.text,
                    description: _descController.text,
                    departmentManagerId: int.parse(_managerIdController.text),
                    userId: userId,
                  );

                  if (success) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Departman başarıyla güncellendi'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadDepartments(); // Listeyi yenile
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Departman güncellenirken hata oluştu. Lütfen terminal loglarını kontrol edin.'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                } else {
                  // Yeni departman ekleme işlemi
                  final userId = AuthService().currentUserId;
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kullanıcı bilgisi bulunamadı')),
                    );
                    return;
                  }

                  final success = await _adminService.addDepartment(
                    departmentName: _nameController.text,
                    description: _descController.text,
                    departmentManagerId: int.parse(_managerIdController.text),
                    userId: userId,
                  );

                  if (success) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Departman başarıyla eklendi'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadDepartments(); // Listeyi yenile
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Departman eklenirken hata oluştu. Lütfen terminal loglarını kontrol edin.'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                }
              }
            },
            child: Text(department != null ? "Güncelle" : "Ekle"),
          ),
        ],
      ),
    );
  }

  void _deleteDepartment(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Bu departmanı silmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final userId = AuthService().currentUserId;
              if (userId == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kullanıcı bilgisi bulunamadı'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              final success = await _adminService.deleteDepartment(
                departmentId: id,
                userId: userId,
              );

              if (success) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Departman başarıyla silindi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadDepartments(); // Listeyi yenile
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Departman silinirken hata oluştu. Lütfen terminal loglarını kontrol edin.'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sayfalama
    final totalPages = (_departments.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = min(startIndex + _itemsPerPage, _departments.length);
    final currentData = _departments.isEmpty ? [] : _departments.sublist(startIndex, endIndex);

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
                    Text("Departman Yönetimi", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text("Departmanları yönetin", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showDepartmentDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Yeni Departman"),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- KART LİSTESİ ---
            _isLoading
                ? const Center(
                    child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator()))
                : currentData.isEmpty
                    ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Kayıt bulunamadı.")))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.8, // Kart boyutu
                            ),
                            itemCount: currentData.length,
                            itemBuilder: (context, index) {
                              return _DepartmentCard(
                                key: ValueKey(currentData[index].departmentId ?? index),
                                department: currentData[index],
                                onEdit: () => _showDepartmentDialog(department: currentData[index]),
                                onDelete: () => _deleteDepartment(currentData[index].departmentId ?? 0),
                              );
                            },
                          );
                        },
                      ),

            // --- SAYFALAMA ---
            const SizedBox(height: 20),
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

// --- DEPARTMAN KARTI ---
class _DepartmentCard extends StatelessWidget {
  final Department department;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DepartmentCard({Key? key, required this.department, required this.onEdit, required this.onDelete}) : super(key: key);

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  department.departmentName ?? 'İsimsiz Departman',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const Divider(height: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tag, size: 16, color: Colors.purple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "DepartmentID: ${department.departmentId ?? 'N/A'}",
                        style: const TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (department.description != null && department.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoRow(icon: Icons.description_outlined, text: department.description!),
                ],
                if (department.manager != null && department.manager!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoRow(icon: Icons.person_outline, text: "Yönetici: ${department.manager}"),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(onTap: onEdit, child: const Icon(Icons.edit, size: 18, color: Colors.teal)),
              const SizedBox(width: 12),
              InkWell(onTap: onDelete, child: const Icon(Icons.delete_outline, size: 18, color: Colors.red)),
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
          child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade700), overflow: TextOverflow.ellipsis, maxLines: 2),
        ),
      ],
    );
  }
}