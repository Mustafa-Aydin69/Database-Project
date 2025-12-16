import 'package:flutter/material.dart';
import 'dart:math';

class PassengersScreen extends StatefulWidget {
  const PassengersScreen({super.key});

  @override
  State<PassengersScreen> createState() => _PassengersScreenState();
}

class _PassengersScreenState extends State<PassengersScreen> {
  // --- STATE ---
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passportController = TextEditingController();
  final TextEditingController _nationalityController = TextEditingController();

  // --- MOCK VERİLER (React'ten alındı) ---
  List<Map<String, dynamic>> _passengers = [
    {'id': 1, 'firstName': 'Ahmet', 'lastName': 'Yılmaz', 'email': 'ahmet.yilmaz@email.com', 'phone': '+90 532 123 4567', 'passportNumber': 'U12345678', 'nationality': 'Türkiye'},
    {'id': 2, 'firstName': 'Ayşe', 'lastName': 'Demir', 'email': 'ayse.demir@email.com', 'phone': '+90 533 234 5678', 'passportNumber': 'U23456789', 'nationality': 'Türkiye'},
    {'id': 3, 'firstName': 'John', 'lastName': 'Smith', 'email': 'john.smith@email.com', 'phone': '+1 555 345 6789', 'passportNumber': 'P34567890', 'nationality': 'USA'},
    {'id': 4, 'firstName': 'Maria', 'lastName': 'Garcia', 'email': 'maria.garcia@email.com', 'phone': '+34 612 456 7890', 'passportNumber': 'E45678901', 'nationality': 'Spain'},
    {'id': 5, 'firstName': 'Mehmet', 'lastName': 'Kaya', 'email': 'mehmet.kaya@email.com', 'phone': '+90 534 567 8901', 'passportNumber': 'U56789012', 'nationality': 'Türkiye'},
    // Sayfalama için veri çoğaltalım
    ...List.generate(15, (index) => {
      'id': 6 + index,
      'firstName': 'Yolcu',
      'lastName': '${index + 1}',
      'email': 'yolcu${index + 1}@email.com',
      'phone': '+90 555 000 ${1000 + index}',
      'passportNumber': 'X${100000 + index}',
      'nationality': index % 3 == 0 ? 'Almanya' : 'Türkiye'
    }),
  ];

  // --- CRUD İŞLEMLERİ ---

  void _showPassengerDialog({Map<String, dynamic>? passenger}) {
    if (passenger != null) {
      _firstNameController.text = passenger['firstName'];
      _lastNameController.text = passenger['lastName'];
      _emailController.text = passenger['email'];
      _phoneController.text = passenger['phone'];
      _passportController.text = passenger['passportNumber'];
      _nationalityController.text = passenger['nationality'];
    } else {
      _firstNameController.clear();
      _lastNameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _passportController.clear();
      _nationalityController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(passenger != null ? 'Yolcu Düzenle' : 'Yeni Yolcu'),
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
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "E-posta", border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                    validator: (v) => v!.isEmpty ? "Zorunlu" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: "Telefon", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                    validator: (v) => v!.isEmpty ? "Zorunlu" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passportController,
                    decoration: const InputDecoration(labelText: "Pasaport No", border: OutlineInputBorder(), prefixIcon: Icon(Icons.book)),
                    validator: (v) => v!.isEmpty ? "Zorunlu" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nationalityController,
                    decoration: const InputDecoration(labelText: "Uyruk", border: OutlineInputBorder(), prefixIcon: Icon(Icons.flag)),
                    validator: (v) => v!.isEmpty ? "Zorunlu" : null,
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
                  if (passenger != null) {
                    final index = _passengers.indexWhere((p) => p['id'] == passenger['id']);
                    _passengers[index] = {
                      'id': passenger['id'],
                      'firstName': _firstNameController.text,
                      'lastName': _lastNameController.text,
                      'email': _emailController.text,
                      'phone': _phoneController.text,
                      'passportNumber': _passportController.text,
                      'nationality': _nationalityController.text,
                    };
                  } else {
                    _passengers.insert(0, {
                      'id': DateTime.now().millisecondsSinceEpoch,
                      'firstName': _firstNameController.text,
                      'lastName': _lastNameController.text,
                      'email': _emailController.text,
                      'phone': _phoneController.text,
                      'passportNumber': _passportController.text,
                      'nationality': _nationalityController.text,
                    });
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text(passenger != null ? "Güncelle" : "Ekle"),
          ),
        ],
      ),
    );
  }

  void _deletePassenger(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Bu yolcuyu silmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          TextButton(
            onPressed: () {
              setState(() => _passengers.removeWhere((p) => p['id'] == id));
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
    final totalPages = (_passengers.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = min(startIndex + _itemsPerPage, _passengers.length);
    final currentData = _passengers.isEmpty ? [] : _passengers.sublist(startIndex, endIndex);

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
                    Text("Yolcu Yönetimi", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text("Yolcuları yönetin", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showPassengerDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Yeni Yolcu"),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- KART LİSTESİ ---
            if (currentData.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Yolcu bulunamadı.")))
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
                      childAspectRatio: 1.8,
                    ),
                    itemCount: currentData.length,
                    itemBuilder: (context, index) {
                      return _PassengerCard(
                        passenger: currentData[index],
                        onEdit: () => _showPassengerDialog(passenger: currentData[index]),
                        onDelete: () => _deletePassenger(currentData[index]['id']),
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

// --- YOLCU KARTI ---
class _PassengerCard extends StatelessWidget {
  final Map<String, dynamic> passenger;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PassengerCard({required this.passenger, required this.onEdit, required this.onDelete});

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
                  Text("${passenger['firstName']} ${passenger['lastName']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("ID: ${passenger['id']}", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(passenger['nationality'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
              ),
            ],
          ),

          const Divider(height: 16),

          _InfoItem(icon: Icons.email_outlined, text: passenger['email']),
          const SizedBox(height: 4),
          _InfoItem(icon: Icons.phone_outlined, text: passenger['phone']),
          const SizedBox(height: 4),
          _InfoItem(icon: Icons.book_outlined, text: passenger['passportNumber']),

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