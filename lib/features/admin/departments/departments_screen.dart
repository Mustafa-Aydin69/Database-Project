import 'package:flutter/material.dart';
import 'dart:math';

class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  // --- STATE ---
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _managerController = TextEditingController();
  final TextEditingController _empCountController = TextEditingController();

  // --- MOCK VERİLER (React'ten alındı) ---
  List<Map<String, dynamic>> _departments = [
    {'id': 1, 'name': 'Uçuş Operasyonları', 'description': 'Uçuş planlaması ve yönetimi', 'manager': 'Ahmet Yılmaz', 'employeeCount': 45},
    {'id': 2, 'name': 'Yer Hizmetleri', 'description': 'Bagaj ve yolcu hizmetleri', 'manager': 'Ayşe Demir', 'employeeCount': 78},
    {'id': 3, 'name': 'Teknik Bakım', 'description': 'Uçak bakım ve onarım', 'manager': 'Mehmet Kaya', 'employeeCount': 62},
    {'id': 4, 'name': 'Güvenlik', 'description': 'Havalimanı güvenlik hizmetleri', 'manager': 'Fatma Şahin', 'employeeCount': 95},
    {'id': 5, 'name': 'Müşteri Hizmetleri', 'description': 'Yolcu destek ve bilgilendirme', 'manager': 'Ali Öztürk', 'employeeCount': 34},
    // Sayfalama için veri çoğaltma
    ...List.generate(10, (index) => {
      'id': 6 + index,
      'name': 'Departman ${index + 1}',
      'description': 'Genel hizmetler departmanı',
      'manager': 'Yönetici ${index + 1}',
      'employeeCount': 20 + index
    }),
  ];

  // --- CRUD İŞLEMLERİ ---

  void _showDepartmentDialog({Map<String, dynamic>? department}) {
    if (department != null) {
      _nameController.text = department['name'];
      _descController.text = department['description'];
      _managerController.text = department['manager'];
      _empCountController.text = department['employeeCount'].toString();
    } else {
      _nameController.clear();
      _descController.clear();
      _managerController.clear();
      _empCountController.clear();
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
                    controller: _managerController,
                    decoration: const InputDecoration(
                      labelText: "Yönetici",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _empCountController,
                    decoration: const InputDecoration(
                      labelText: "Çalışan Sayısı",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.isEmpty || int.tryParse(v) == null) ? "Geçerli sayı giriniz" : null,
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
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  if (department != null) {
                    final index = _departments.indexWhere((d) => d['id'] == department['id']);
                    _departments[index] = {
                      'id': department['id'],
                      'name': _nameController.text,
                      'description': _descController.text,
                      'manager': _managerController.text,
                      'employeeCount': int.parse(_empCountController.text),
                    };
                  } else {
                    _departments.insert(0, {
                      'id': DateTime.now().millisecondsSinceEpoch,
                      'name': _nameController.text,
                      'description': _descController.text,
                      'manager': _managerController.text,
                      'employeeCount': int.parse(_empCountController.text),
                    });
                  }
                });
                Navigator.pop(context);
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
            onPressed: () {
              setState(() => _departments.removeWhere((d) => d['id'] == id));
              Navigator.pop(context);
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
            if (currentData.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Kayıt bulunamadı.")))
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
                      childAspectRatio: 1.8, // Kart boyutu
                    ),
                    itemCount: currentData.length,
                    itemBuilder: (context, index) {
                      return _DepartmentCard(
                        department: currentData[index],
                        onEdit: () => _showDepartmentDialog(department: currentData[index]),
                        onDelete: () => _deleteDepartment(currentData[index]['id']),
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
  final Map<String, dynamic> department;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DepartmentCard({required this.department, required this.onEdit, required this.onDelete});

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
                  department['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(4)),
                child: Text(
                  "${department['employeeCount']} Çalışan",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                ),
              ),
            ],
          ),

          const Divider(height: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(icon: Icons.description_outlined, text: department['description']),
                const SizedBox(height: 8),
                _InfoRow(icon: Icons.person_outline, text: "Yönetici: ${department['manager']}"),
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