import 'package:flutter/material.dart';
import 'dart:math';
import '../../../core/services/admin_service.dart';
import '../../../core/services/auth_service.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  // --- STATE ---
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<Employee> _employees = [];
  List<Department> _departments = [];
  int? _selectedDepartmentId; // Seçilen departman ID'si
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

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _loadDepartments();
  }

  /// API'den departman listesini yükle
  Future<void> _loadDepartments() async {
    try {
      final departments = await _adminService.getDepartments();
      setState(() {
        _departments = departments;
      });
    } catch (e) {
      debugPrint('❌ Error loading departments: $e');
    }
  }

  /// API'den çalışan listesini yükle
  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final employees = await _adminService.getEmployees();
      debugPrint('📥 Employees loaded: ${employees.length} items');
      
      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading employees: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- MOCK VERİLER (KALDIRILDI) ---
  /* List<Map<String, dynamic>> _employees = [
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
  ]; */

  // --- CRUD İŞLEMLERİ ---

  void _showEmployeeDialog({Employee? employee}) {
    if (employee != null) {
      _firstNameController.text = employee.firstName ?? '';
      _lastNameController.text = employee.lastName ?? '';
      _phoneController.text = employee.contact ?? '';
      _deptController.text = employee.departmentName ?? '';
      _posController.text = employee.role ?? '';
      _salaryController.text = employee.salary?.toString() ?? '';
      _selectedDepartmentId = employee.departmentId;
    } else {
      _firstNameController.clear();
      _lastNameController.clear();
      _phoneController.clear();
      _deptController.clear();
      _posController.clear();
      _salaryController.clear();
      _selectedDepartmentId = null;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                  DropdownButtonFormField<int>(
                    value: employee != null ? employee.departmentId : _selectedDepartmentId,
                    decoration: const InputDecoration(
                      labelText: "Departman",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    items: _departments.map((dept) {
                      return DropdownMenuItem<int>(
                        value: dept.departmentId,
                        child: Text(dept.departmentName ?? 'İsimsiz Departman'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedDepartmentId = value;
                        if (value != null) {
                          final dept = _departments.firstWhere((d) => d.departmentId == value);
                          _deptController.text = dept.departmentName ?? '';
                        }
                      });
                    },
                    validator: (v) => v == null ? "Zorunlu" : null,
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
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                if (employee != null) {
                  // Güncelleme işlemi
                  final userId = AuthService().currentUserId;
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kullanıcı bilgisi bulunamadı')),
                    );
                    return;
                  }

                  // DepartmentID'yi almak için mevcut employee'dan alıyoruz
                  // Eğer form'da DepartmentID seçimi varsa onu kullanabiliriz
                  final departmentId = employee.departmentId;
                  if (departmentId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Departman bilgisi bulunamadı')),
                    );
                    return;
                  }

                  final salary = double.tryParse(_salaryController.text);
                  if (salary == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Geçerli bir maaş giriniz')),
                    );
                    return;
                  }

                  final success = await _adminService.updateEmployee(
                    employeeId: employee.employeeId!,
                    firstName: _firstNameController.text,
                    lastName: _lastNameController.text,
                    departmentId: departmentId,
                    salary: salary,
                    contact: _phoneController.text,
                    role: _posController.text,
                    userId: userId,
                  );

                  if (success) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Çalışan başarıyla güncellendi'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadEmployees(); // Listeyi yenile
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Çalışan güncellenirken hata oluştu. Lütfen terminal loglarını kontrol edin.'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                } else {
                  // Yeni çalışan ekleme işlemi
                  final userId = AuthService().currentUserId;
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kullanıcı bilgisi bulunamadı')),
                    );
                    return;
                  }

                  if (_selectedDepartmentId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lütfen bir departman seçiniz')),
                    );
                    return;
                  }

                  final salary = double.tryParse(_salaryController.text);
                  if (salary == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Geçerli bir maaş giriniz')),
                    );
                    return;
                  }

                  final success = await _adminService.addEmployee(
                    firstName: _firstNameController.text,
                    lastName: _lastNameController.text,
                    departmentId: _selectedDepartmentId!,
                    salary: salary,
                    contact: _phoneController.text,
                    role: _posController.text,
                    userId: userId,
                  );

                  if (success) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Çalışan başarıyla eklendi'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadEmployees(); // Listeyi yenile
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Çalışan eklenirken hata oluştu. Lütfen terminal loglarını kontrol edin.'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                }
              }
            },
            child: Text(employee != null ? "Güncelle" : "Ekle"),
          ),
        ],
        ),
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
            onPressed: () async {
              Navigator.pop(context);
              
              if (!mounted) return;
              
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

              final success = await _adminService.deleteEmployee(
                employeeId: id,
                userId: userId,
              );

              if (!mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Çalışan başarıyla silindi'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadEmployees(); // Listeyi yenile
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Çalışan silinirken hata oluştu. Bu çalışan bir departmanın yöneticisi olabilir. Lütfen önce departman yöneticisini değiştirin.'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 5),
                  ),
                );
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
            _isLoading
                ? const Center(
                    child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator()))
                : currentData.isEmpty
                    ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Çalışan bulunamadı.")))
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
                              childAspectRatio: 1.8, // Kart boyutu biraz genişletildi
                            ),
                            itemCount: currentData.length,
                            itemBuilder: (context, index) {
                              return _EmployeeCard(
                                key: ValueKey(currentData[index].employeeId ?? index),
                                employee: currentData[index],
                                onEdit: () => _showEmployeeDialog(employee: currentData[index]),
                                onDelete: () => _deleteEmployee(currentData[index].employeeId ?? 0),
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
  final Employee employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EmployeeCard({Key? key, required this.employee, required this.onEdit, required this.onDelete}) : super(key: key);

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
                  Text("${employee.firstName ?? ''} ${employee.lastName ?? ''}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("ID: ${employee.employeeId ?? 'N/A'}", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(employee.role ?? 'N/A', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
              ),
            ],
          ),

          const Divider(height: 16),

          if (employee.departmentName != null && employee.departmentName!.isNotEmpty)
            _InfoItem(icon: Icons.business, text: employee.departmentName!),
          if (employee.departmentName != null && employee.departmentName!.isNotEmpty)
            const SizedBox(height: 4),
          if (employee.contact != null && employee.contact!.isNotEmpty)
            _InfoItem(icon: Icons.phone_outlined, text: employee.contact!),
          if (employee.contact != null && employee.contact!.isNotEmpty)
            const SizedBox(height: 4),
          if (employee.salary != null)
            _InfoItem(icon: Icons.monetization_on, text: "Maaş: ${employee.salary!.toStringAsFixed(2)} ₺"),

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