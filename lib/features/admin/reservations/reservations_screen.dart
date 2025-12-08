import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  // --- STATE ---
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  String _searchTerm = "";

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passengerController = TextEditingController();
  final TextEditingController _flightNoController = TextEditingController();
  final TextEditingController _seatNoController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String _selectedStatus = 'Pending';
  DateTime? _bookingDate;

  // Sabit Listeler
  final List<String> _statuses = ['Confirmed', 'Pending', 'Cancelled'];

  // --- MOCK VERİLER (React'ten alındı) ---
  List<Map<String, dynamic>> _reservations = [
    {
      'id': 1, 'passengerName': 'Ahmet Yılmaz', 'flightNumber': 'TK1234',
      'seatNumber': '12A', 'bookingDate': '2024-01-10', 'status': 'Confirmed', 'price': 1250.0
    },
    {
      'id': 2, 'passengerName': 'Ayşe Demir', 'flightNumber': 'PC5678',
      'seatNumber': '8C', 'bookingDate': '2024-01-11', 'status': 'Pending', 'price': 890.0
    },
    {
      'id': 3, 'passengerName': 'Mehmet Kaya', 'flightNumber': 'TK9012',
      'seatNumber': '15F', 'bookingDate': '2024-01-12', 'status': 'Cancelled', 'price': 1450.0
    },
    {
      'id': 4, 'passengerName': 'Fatma Şahin', 'flightNumber': 'AJ3456',
      'seatNumber': '22B', 'bookingDate': '2024-01-13', 'status': 'Confirmed', 'price': 980.0
    },
    {
      'id': 5, 'passengerName': 'Ali Öztürk', 'flightNumber': 'TK7890',
      'seatNumber': '5D', 'bookingDate': '2024-01-14', 'status': 'Confirmed', 'price': 2100.0
    },
    // Sayfalama için ek veri
    ...List.generate(15, (index) => {
      'id': 6 + index,
      'passengerName': 'Yolcu ${index + 1}',
      'flightNumber': 'TK${1000 + index}',
      'seatNumber': '${index + 1}A',
      'bookingDate': '2024-01-${15 + index}',
      'status': index % 3 == 0 ? 'Confirmed' : (index % 3 == 1 ? 'Pending' : 'Cancelled'),
      'price': 1000.0 + (index * 50)
    }),
  ];

  // --- FİLTRELEME ---
  List<Map<String, dynamic>> get _filteredReservations {
    return _reservations.where((r) {
      return r['passengerName'].toString().toLowerCase().contains(_searchTerm.toLowerCase()) ||
          r['flightNumber'].toString().toLowerCase().contains(_searchTerm.toLowerCase());
    }).toList();
  }

  // --- CRUD İŞLEMLERİ ---

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _bookingDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != _bookingDate) {
      setState(() {
        _bookingDate = picked;
      });
    }
  }

  void _showReservationDialog({Map<String, dynamic>? reservation}) {
    if (reservation != null) {
      _passengerController.text = reservation['passengerName'];
      _flightNoController.text = reservation['flightNumber'];
      _seatNoController.text = reservation['seatNumber'];
      _priceController.text = reservation['price'].toString();
      _selectedStatus = reservation['status'];
      _bookingDate = DateTime.parse(reservation['bookingDate']);
    } else {
      _passengerController.clear();
      _flightNoController.clear();
      _seatNoController.clear();
      _priceController.clear();
      _selectedStatus = 'Pending';
      _bookingDate = DateTime.now();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    controller: _passengerController,
                    decoration: const InputDecoration(labelText: "Yolcu Adı", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                    validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _flightNoController,
                          decoration: const InputDecoration(labelText: "Uçuş No", border: OutlineInputBorder(), prefixIcon: Icon(Icons.flight)),
                          validator: (v) => v!.isEmpty ? "Gerekli" : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _seatNoController,
                          decoration: const InputDecoration(labelText: "Koltuk No", border: OutlineInputBorder(), prefixIcon: Icon(Icons.event_seat)),
                          validator: (v) => v!.isEmpty ? "Gerekli" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: "Tarih", border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                      child: Text(_bookingDate == null ? "Seçiniz" : DateFormat('yyyy-MM-dd').format(_bookingDate!)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: const InputDecoration(labelText: "Durum", border: OutlineInputBorder()),
                          items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) => setState(() => _selectedStatus = val!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(labelText: "Fiyat (₺)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? "Gerekli" : null,
                        ),
                      ),
                    ],
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
              if (_formKey.currentState!.validate() && _bookingDate != null) {
                setState(() {
                  if (reservation != null) {
                    final index = _reservations.indexWhere((r) => r['id'] == reservation['id']);
                    _reservations[index] = {
                      'id': reservation['id'],
                      'passengerName': _passengerController.text,
                      'flightNumber': _flightNoController.text,
                      'seatNumber': _seatNoController.text,
                      'bookingDate': DateFormat('yyyy-MM-dd').format(_bookingDate!),
                      'status': _selectedStatus,
                      'price': double.parse(_priceController.text),
                    };
                  } else {
                    _reservations.insert(0, {
                      'id': DateTime.now().millisecondsSinceEpoch,
                      'passengerName': _passengerController.text,
                      'flightNumber': _flightNoController.text,
                      'seatNumber': _seatNoController.text,
                      'bookingDate': DateFormat('yyyy-MM-dd').format(_bookingDate!),
                      'status': _selectedStatus,
                      'price': double.parse(_priceController.text),
                    });
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text(reservation != null ? "Güncelle" : "Ekle"),
          ),
        ],
      ),
    );
  }

  void _deleteReservation(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Bu rezervasyonu silmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          TextButton(
            onPressed: () {
              setState(() => _reservations.removeWhere((r) => r['id'] == id));
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
                    Text("Rezervasyon Yönetimi", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text("Rezervasyonları yönetin", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showReservationDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Yeni Rezervasyon"),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- ARAMA ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: TextField(
                onChanged: (val) => setState(() => _searchTerm = val),
                decoration: const InputDecoration(
                  hintText: "Yolcu adı veya uçuş no ile ara...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
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
                      childAspectRatio: 1.8,
                    ),
                    itemCount: currentData.length,
                    itemBuilder: (context, index) {
                      return _ReservationCard(
                        reservation: currentData[index],
                        onEdit: () => context.go('/admin/reservations/${currentData[index]['id']}'),
                        onDelete: () => _deleteReservation(currentData[index]['id']),
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

// --- REZERVASYON KARTI ---
class _ReservationCard extends StatelessWidget {
  final Map<String, dynamic> reservation;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReservationCard({required this.reservation, required this.onEdit, required this.onDelete});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed': return Colors.green;
      case 'Pending': return Colors.orange;
      case 'Cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(reservation['status']);
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

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
                  reservation['passengerName'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(reservation['status'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),

          const Divider(height: 16),

          Row(
            children: [
              const Icon(Icons.flight, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(reservation['flightNumber'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const Spacer(),
              const Icon(Icons.event_seat, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(reservation['seatNumber'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(reservation['bookingDate'], style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            ],
          ),

          const Divider(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currencyFormat.format(reservation['price']),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
              ),
              Row(
                children: [
                  InkWell(onTap: onEdit, child: const Icon(Icons.edit, size: 20, color: Colors.teal)),
                  const SizedBox(width: 12),
                  InkWell(onTap: onDelete, child: const Icon(Icons.delete_outline, size: 20, color: Colors.red)),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}