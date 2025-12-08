import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class ParkingReservationsScreen extends StatefulWidget {
  const ParkingReservationsScreen({super.key});

  @override
  State<ParkingReservationsScreen> createState() => _ParkingReservationsScreenState();
}

class _ParkingReservationsScreenState extends State<ParkingReservationsScreen> {
  // --- STATE ---
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  String _searchTerm = "";
  String _filterStatus = "all";

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  String _selectedStatus = "active";

  // Sabit Listeler
  final List<String> _statuses = ['active', 'completed', 'cancelled', 'pending'];

  // --- MOCK VERİLER ---
  List<Map<String, dynamic>> _reservations = [
    {
      'id': 'RES-001', 'plateNumber': '34 ABC 123', 'airport': 'İstanbul Havalimanı (IST)',
      'parkingLot': 'A Terminali Otopark', 'spotCode': 'A-15', 'customerName': 'Ahmet Yılmaz',
      'phone': '+90 532 123 4567', 'startDate': '2024-01-15 10:00', 'endDate': '2024-01-20 14:00',
      'vehicleType': 'Sedan', 'status': 'active', 'amount': 750
    },
    {
      'id': 'RES-002', 'plateNumber': '06 XYZ 789', 'airport': 'Esenboğa Havalimanı (ESB)',
      'parkingLot': 'Terminal Otopark', 'spotCode': 'B-08', 'customerName': 'Ayşe Demir',
      'phone': '+90 533 987 6543', 'startDate': '2024-01-16 08:30', 'endDate': '2024-01-18 16:00',
      'vehicleType': 'SUV', 'status': 'active', 'amount': 450
    },
    {
      'id': 'RES-003', 'plateNumber': '35 DEF 456', 'airport': 'Sabiha Gökçen (SAW)',
      'parkingLot': 'Kapalı Otopark', 'spotCode': 'C-22', 'customerName': 'Mehmet Kaya',
      'phone': '+90 534 555 1234', 'startDate': '2024-01-10 12:00', 'endDate': '2024-01-14 10:00',
      'vehicleType': 'Sedan', 'status': 'completed', 'amount': 600
    },
    // Sayfalama verisi
    ...List.generate(15, (index) => {
      'id': 'RES-${100 + index}',
      'plateNumber': '34 TES ${100 + index}',
      'airport': 'İstanbul Havalimanı (IST)',
      'parkingLot': 'Genel Otopark',
      'spotCode': 'P-${index + 1}',
      'customerName': 'Misafir ${index + 1}',
      'phone': '+90 555 000 ${1000 + index}',
      'startDate': '2024-01-${10 + index} 10:00',
      'endDate': '2024-01-${12 + index} 14:00',
      'vehicleType': 'Sedan',
      'status': index % 2 == 0 ? 'active' : 'completed',
      'amount': 300 + (index * 20)
    }),
  ];

  // --- FİLTRELEME ---
  List<Map<String, dynamic>> get _filteredReservations {
    return _reservations.where((r) {
      final matchesSearch = r['plateNumber'].toLowerCase().contains(_searchTerm.toLowerCase()) ||
          r['customerName'].toLowerCase().contains(_searchTerm.toLowerCase()) ||
          r['id'].toLowerCase().contains(_searchTerm.toLowerCase());

      final matchesStatus = _filterStatus == 'all' || r['status'] == _filterStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  // --- CRUD İŞLEMLERİ ---
  Future<void> _selectDateTime(BuildContext context, TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2025),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        final dt = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
        controller.text = DateFormat('yyyy-MM-dd HH:mm').format(dt);
      }
    }
  }

  void _showReservationDialog({Map<String, dynamic>? reservation}) {
    if (reservation != null) {
      _plateController.text = reservation['plateNumber'];
      _customerNameController.text = reservation['customerName'];
      _phoneController.text = reservation['phone'];
      _startDateController.text = reservation['startDate'];
      _endDateController.text = reservation['endDate'];
      _selectedStatus = reservation['status'];
    } else {
      _plateController.clear();
      _customerNameController.clear();
      _phoneController.clear();
      _startDateController.clear();
      _endDateController.clear();
      _selectedStatus = 'active';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reservation != null ? 'Rezervasyon Düzenle' : 'Yeni Rezervasyon'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _plateController,
                    decoration: const InputDecoration(labelText: "Plaka", border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? "Zorunlu" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(labelText: "Müşteri Adı", border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? "Zorunlu" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: "Telefon", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _startDateController,
                    readOnly: true,
                    onTap: () => _selectDateTime(context, _startDateController),
                    decoration: const InputDecoration(labelText: "Başlangıç", border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _endDateController,
                    readOnly: true,
                    onTap: () => _selectDateTime(context, _endDateController),
                    decoration: const InputDecoration(labelText: "Bitiş", border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(labelText: "Durum", border: OutlineInputBorder()),
                    items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => _selectedStatus = val!),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  if (reservation != null) {
                    final index = _reservations.indexWhere((r) => r['id'] == reservation['id']);
                    _reservations[index] = {
                      ..._reservations[index],
                      'plateNumber': _plateController.text,
                      'customerName': _customerNameController.text,
                      'phone': _phoneController.text,
                      'startDate': _startDateController.text,
                      'endDate': _endDateController.text,
                      'status': _selectedStatus,
                    };
                  } else {
                    _reservations.insert(0, {
                      'id': 'RES-${DateTime.now().millisecondsSinceEpoch}',
                      'plateNumber': _plateController.text,
                      'customerName': _customerNameController.text,
                      'phone': _phoneController.text,
                      'startDate': _startDateController.text,
                      'endDate': _endDateController.text,
                      'status': _selectedStatus,
                      'amount': 0, // Yeni kayıtta hesaplanabilir
                      'airport': 'İstanbul Havalimanı (IST)', // Varsayılan
                      'parkingLot': 'Genel',
                      'spotCode': 'P-Temp'
                    });
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text(reservation != null ? "Güncelle" : "Oluştur"),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rezervasyon Detayları"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow("Rezervasyon No", reservation['id']),
            _DetailRow("Plaka", reservation['plateNumber']),
            _DetailRow("Müşteri", reservation['customerName']),
            _DetailRow("Telefon", reservation['phone']),
            _DetailRow("Park Yeri", "${reservation['parkingLot']} - ${reservation['spotCode']}"),
            _DetailRow("Başlangıç", reservation['startDate']),
            _DetailRow("Bitiş", reservation['endDate']),
            _DetailRow("Tutar", "${reservation['amount']} ₺", isBold: true, color: Colors.teal),
            _DetailRow("Durum", reservation['status'], isBold: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredReservations;
    final totalPages = (filtered.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = min(startIndex + _itemsPerPage, filtered.length);
    final currentData = filtered.isEmpty ? [] : filtered.sublist(startIndex, endIndex);

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
                    Text("Rezervasyonlar", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text("Otopark rezervasyon işlemlerini yönetin", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showReservationDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Yeni Rezervasyon"),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- FİLTRELER ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 600;
                  return Flex(
                    direction: isMobile ? Axis.vertical : Axis.horizontal,
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchTerm = val),
                          decoration: const InputDecoration(
                            hintText: "Plaka, müşteri veya ID ara...",
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
                      SizedBox(
                        width: isMobile ? double.infinity : 200,
                        child: DropdownButtonFormField<String>(
                          value: _filterStatus == 'all' ? null : _filterStatus,
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12), hintText: "Tüm Durumlar"),
                          items: [
                            const DropdownMenuItem(value: "", child: Text("Tüm Durumlar")),
                            ..._statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                          ],
                          onChanged: (val) => setState(() => _filterStatus = val ?? "all"),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // --- KART LİSTESİ ---
            if (currentData.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Rezervasyon bulunamadı.")))
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
                      childAspectRatio: 1.6,
                    ),
                    itemCount: currentData.length,
                    itemBuilder: (context, index) {
                      return _ReservationCard(
                        reservation: currentData[index],
                        onEdit: () => _showReservationDialog(reservation: currentData[index]),
                        onView: () => _showDetailDialog(currentData[index]),
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

// --- KART WIDGETLARI ---
class _ReservationCard extends StatelessWidget {
  final Map<String, dynamic> reservation;
  final VoidCallback onEdit;
  final VoidCallback onView;

  const _ReservationCard({required this.reservation, required this.onEdit, required this.onView});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active': return Colors.green;
      case 'completed': return Colors.grey;
      case 'cancelled': return Colors.red;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(reservation['status']);

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
              Text(reservation['plateNumber'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(reservation['status'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),

          const Divider(height: 16),

          _InfoRow(label: "Müşteri", value: reservation['customerName']),
          _InfoRow(label: "Park Yeri", value: reservation['spotCode']),
          _InfoRow(label: "Giriş", value: reservation['startDate']),
          _InfoRow(label: "Çıkış", value: reservation['endDate']),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(onTap: onView, child: const Icon(Icons.visibility, size: 20, color: Colors.blue)),
              const SizedBox(width: 16),
              InkWell(onTap: onEdit, child: const Icon(Icons.edit, size: 20, color: Colors.orange)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;
  const _DetailRow(this.label, this.value, {this.isBold = false, this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? Colors.black87)),
        ],
      ),
    );
  }
}