import 'package:flutter/material.dart';
import 'dart:math';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  // --- STATE ---
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _deptController = TextEditingController();
  final TextEditingController _posController = TextEditingController();
  // Email ve Tarih silindi, Maaş eklendi:
  final TextEditingController _salaryController = TextEditingController();

  // --- MOCK VERİLER ---
  List<Map<String, dynamic>> _employees = [
    {
      'id': 1, 
      'firstName': 'Ahmet', 
      'lastName': 'Yılmaz', 
      'phone': '+90 532 123 4567', 
      'department': 'Uçuş Operasyonları', 
      'position': 'Operasyon Müdürü', 
      'salary': 45000 // Maaş eklendi
    },
    {
      'id': 2, 
      'firstName': 'Ayşe', 
      'lastName': 'Demir', 
      'phone': '+90 533 234 5678', 
      'department': 'Yer Hizmetleri', 
      'position': 'Yer Hizmetleri Müdürü', 
      'salary': 38000
    },
    {
      'id': 3, 
      'firstName': 'Mehmet', 
      'lastName': 'Kaya', 
      'phone': '+90 534 345 6789', 
      'department': 'Teknik Bakım', 
      'position': 'Bakım Mühendisi', 
      'salary': 42000
    },
    {
      'id': 4, 
      'firstName': 'Fatma', 
      'lastName': 'Şahin', 
      'phone': '+90 535 456 7890', 
      'department': 'Güvenlik', 
      'position': 'Güvenlik Şefi', 
      'salary': 32000
    },
    {
      'id': 5, 
      'firstName': 'Ali', 
      'lastName': 'Öztürk', 
      'phone': '+90 536 567 8901', 
      'department': 'Müşteri Hizmetleri', 
      'position': 'Müşteri Temsilcisi', 
      'salary': 28500
    },
    // Sayfalama için veri çoğaltma
    ...List.generate(15, (index) => {
      'id': 6 + index,
      'firstName': 'Personel',
      'lastName': '${index + 1}',
      'phone': '+90 555 000 ${1000 + index}',
      'department': index % 2 == 0 ? 'Yer Hizmetleri' : 'Teknik Bakım',
      'position': 'Uzman',
      'salary': 25000 + (index * 500) // Dinamik maaş
    }),
  ];

  // --- CRUD İŞLEMLERİ ---

  void _showEmployeeDialog({Map<String, dynamic>? employee}) {
    if (employee != null) {
      _firstNameController.text = employee['firstName'];
      _lastNameController.text = employee['lastName'];
      // Email ve Tarih setleme kaldırıldı
      _phoneController.text = employee['phone'];
      _deptController.text = employee['department'];
      _posController.text = employee['position'];
      _salaryController.text = employee['salary'].toString(); // Maaş setlendi
    } else {
      _firstNameController.clear();
      _lastNameController.clear();
      // Email ve Tarih clear kaldırıldı
      _phoneController.clear();
      _deptController.clear();
      _posController.clear();
      _salaryController.clear(); // Maaş temizlendi
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(employee != null ? 'Çalışan Düzenle' : 'Yeni Çalışan'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(labelText: "Ad", border: OutlineInputBorder()),
                          validator: (v) => v!.isEmpty ? "Zorunlu" : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(labelText: "Soyad", border: OutlineInputBorder()),
                          validator: (v) => v!.isEmpty ? "Zorunlu" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Email Alanı Kaldırıldı
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: "Telefon", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                    validator: (v) => v!.isEmpty ? "Zorunlu" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _deptController,
                    decoration: const InputDecoration(labelText: "Departman", border: OutlineInputBorder(), prefixIcon: Icon(Icons.business)),
                    validator: (v) => v!.isEmpty ? "Zorunlu" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _posController,
                    decoration: const InputDecoration(labelText: "Pozisyon", border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge)),
                    validator: (v) => v!.isEmpty ? "Zorunlu" : null,
                  ),
                  const SizedBox(height: 16),
                  // İşe Giriş Tarihi Kaldırıldı
                  
                  // YENİ MAAŞ ALANI EKLENDİ
                  TextFormField(
                    controller: _salaryController,
                    decoration: const InputDecoration(
                      labelText: "Maaş (₺)", 
                      border: OutlineInputBorder(), 
                      prefixIcon: Icon(Icons.monetization_on)
                    ),
                    keyboardType: TextInputType.number, // Sadece sayısal klavye
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Zorunlu";
                      if (double.tryParse(v) == null) return "Geçerli bir sayı giriniz";
                      if (double.parse(v) < 0) return "Negatif olamaz";
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  if (employee != null) {
                    final index = _employees.indexWhere((e) => e['id'] == employee['id']);
                    _employees[index] = {
                      'id': employee['id'],
                      'firstName': _firstNameController.text,
                      'lastName': _lastNameController.text,
                      // Email ve Tarih kaydetme kaldırıldı
                      'phone': _phoneController.text,
                      'department': _deptController.text,
                      'position': _posController.text,
                      'salary': int.parse(_salaryController.text), // Maaş integer olarak kaydediliyor
                    };
                  } else {
                    _employees.insert(0, {
                      'id': DateTime.now().millisecondsSinceEpoch,
                      'firstName': _firstNameController.text,
                      'lastName': _lastNameController.text,
                      // Email ve Tarih kaydetme kaldırıldı
                      'phone': _phoneController.text,
                      'department': _deptController.text,
                      'position': _posController.text,
                      'salary': int.parse(_salaryController.text), // Maaş kaydediliyor
                    });
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text(employee != null ? "Güncelle" : "Ekle"),
          ),
        ],
      ),
    );
  }

  void _deleteEmployee(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Bu çalışanı silmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          TextButton(
            onPressed: () {
              setState(() => _employees.removeWhere((e) => e['id'] == id));
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
    final totalPages = (_employees.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = min(startIndex + _itemsPerPage, _employees.length);
    final currentData = _employees.isEmpty ? [] : _employees.sublist(startIndex, endIndex);

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
                    Text("Çalışan Yönetimi", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text("Çalışanları yönetin", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showEmployeeDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Yeni Çalışan"),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- KART LİSTESİ ---
            if (currentData.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Çalışan bulunamadı.")))
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
                      childAspectRatio: 1.8, // Kart boyutu biraz genişletildi
                    ),
                    itemCount: currentData.length,
                    itemBuilder: (context, index) {
                      return _EmployeeCard(
                        employee: currentData[index],
                        onEdit: () => _showEmployeeDialog(employee: currentData[index]),
                        onDelete: () => _deleteEmployee(currentData[index]['id']),
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

// --- ÇALIŞAN KARTI ---
class _EmployeeCard extends StatelessWidget {
  final Map<String, dynamic> employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EmployeeCard({required this.employee, required this.onEdit, required this.onDelete});

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${employee['firstName']} ${employee['lastName']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("ID: ${employee['id']}", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(employee['position'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
              ),
            ],
          ),

          const Divider(height: 16),

          _InfoItem(icon: Icons.business, text: employee['department']),
          const SizedBox(height: 4),
          // Email Kaldırıldı
          _InfoItem(icon: Icons.phone_outlined, text: employee['phone']),
          const SizedBox(height: 4),
          // Giriş Tarihi Kaldırıldı, yerine Maaş Eklendi
          _InfoItem(icon: Icons.monetization_on, text: "Maaş: ${employee['salary']} ₺"),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(onTap: onEdit, child: const Icon(Icons.edit, size: 20, color: Colors.teal)),
              const SizedBox(width: 16),
              InkWell(onTap: onDelete, child: const Icon(Icons.delete_outline, size: 20, color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoItem({required this.icon, required this.text});
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