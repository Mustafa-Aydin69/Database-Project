import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/services/auth_service.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  @override
  void dispose() {
    _passengerController.dispose();
    _flightNoController.dispose();
    _seatNoController.dispose();
    _priceController.dispose();
    _bookingDateController.dispose();
    _passportNoController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // --- STATE ---
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<Reservation> _reservations = [];
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  String _searchTerm = "";

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passengerController = TextEditingController();
  final TextEditingController _flightNoController = TextEditingController();
  final TextEditingController _seatNoController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _bookingDateController = TextEditingController();
  final TextEditingController _passportNoController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _selectedStatus = 'Pending';
  DateTime? _bookingDate;

  // Sabit Listeler
  final List<String> _statuses = ['Confirmed', 'Pending', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  /// API'den rezervasyon listesini yükle
  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reservations = await _adminService.getReservations();
      debugPrint('📥 Reservations loaded: ${reservations.length} items');
      
      setState(() {
        _reservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading reservations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- MOCK VERİLER (KALDIRILDI) ---
  /* List<Map<String, dynamic>> _reservations = [
    {
      'id': 1,
      'passengerName': 'Ahmet Yılmaz',
      'flightNumber': 'TK1234',
      'seatNumber': '12A',
      'bookingDate': '2024-01-10',
      'status': 'Confirmed',
      'price': 1250.0,
    },
    {
      'id': 2,
      'passengerName': 'Ayşe Demir',
      'flightNumber': 'PC5678',
      'seatNumber': '8C',
      'bookingDate': '2024-01-11',
      'status': 'Pending',
      'price': 890.0,
    },
    {
      'id': 3,
      'passengerName': 'Mehmet Kaya',
      'flightNumber': 'TK9012',
      'seatNumber': '15F',
      'bookingDate': '2024-01-12',
      'status': 'Cancelled',
      'price': 1450.0,
    },
    {
      'id': 4,
      'passengerName': 'Fatma Şahin',
      'flightNumber': 'AJ3456',
      'seatNumber': '22B',
      'bookingDate': '2024-01-13',
      'status': 'Confirmed',
      'price': 980.0,
    },
    {
      'id': 5,
      'passengerName': 'Ali Öztürk',
      'flightNumber': 'TK7890',
      'seatNumber': '5D',
      'bookingDate': '2024-01-14',
      'status': 'Confirmed',
      'price': 2100.0,
    },
    // Sayfalama için ek veri
    ...List.generate(
      15,
      (index) => {
        'id': 6 + index,
        'passengerName': 'Yolcu ${index + 1}',
        'flightNumber': 'TK${1000 + index}',
        'seatNumber': '${index + 1}A',
        'bookingDate': '2024-01-${15 + index}',
        'status': index % 3 == 0
            ? 'Confirmed'
            : (index % 3 == 1 ? 'Pending' : 'Cancelled'),
        'price': 1000.0 + (index * 50),
      },
    ),
  ]; */

  // --- FİLTRELEME ---
  List<Reservation> get _filteredReservations {
    return _reservations.where((r) {
      return (r.passengerName ?? '').toLowerCase().contains(
            _searchTerm.toLowerCase(),
          ) ||
          (r.flightCode ?? '').toLowerCase().contains(
            _searchTerm.toLowerCase(),
          ) ||
          (r.customerName ?? '').toLowerCase().contains(
            _searchTerm.toLowerCase(),
          );
    }).toList();
  }

  // --- CRUD İŞLEMLERİ ---

  void _showReservationDialog({Reservation? reservation}) {
    if (reservation != null) {
      _passengerController.text = reservation.passengerName ?? '';
      _flightNoController.text = reservation.flightCode ?? '';
      _seatNoController.text = reservation.seatNumber ?? '';
      _priceController.text = reservation.totalAmount?.toString() ?? '';
      _selectedStatus = reservation.reservationStatus ?? 'Pending';
      if (reservation.reservationDate != null) {
        try {
          _bookingDate = DateTime.parse(reservation.reservationDate!);
          _bookingDateController.text = DateFormat('dd.MM.yyyy').format(_bookingDate!);
        } catch (e) {
          _bookingDate = null;
          _bookingDateController.clear();
        }
      } else {
        _bookingDate = null;
        _bookingDateController.clear();
      }
    } else {
      _passengerController.clear();
      _flightNoController.clear();
      _seatNoController.clear();
      _priceController.clear();
      _passportNoController.clear();
      _ageController.clear();
      _selectedStatus = 'Pending';
      _bookingDate = null;
      _bookingDateController.clear();
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              reservation != null
                  ? 'Rezervasyon Görüntüle'
                  : 'Yeni Rezervasyon',
            ),
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
                        decoration: const InputDecoration(
                          labelText: "Yolcu Adı",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _flightNoController,
                              decoration: const InputDecoration(
                                labelText: "Uçuş No",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.flight),
                              ),
                              validator: (v) => v!.isEmpty ? "Gerekli" : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _seatNoController,
                              decoration: const InputDecoration(
                                labelText: "Koltuk No",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.event_seat),
                              ),
                              validator: (v) => v!.isEmpty ? "Gerekli" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () async {
                          FocusScope.of(context).unfocus();
                          final now = DateTime.now();
                          final initialDate = _bookingDate ?? now;
                          // initialDate lastDate'den sonra olamaz, bu yüzden kontrol ediyoruz
                          final safeInitialDate = initialDate.isAfter(DateTime(2030, 12, 31))
                              ? now
                              : initialDate;
                          
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: safeInitialDate,
                            firstDate: DateTime(2023),
                            lastDate: DateTime(2030, 12, 31),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              _bookingDate = picked;
                              _bookingDateController.text = DateFormat('dd.MM.yyyy').format(picked);
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: "Tarih",
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            controller: _bookingDateController,
                            validator: (v) =>
                                _bookingDate == null ? "Tarih seçiniz" : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _passportNoController,
                              decoration: const InputDecoration(
                                labelText: "Pasaport No",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.badge),
                              ),
                              validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              decoration: const InputDecoration(
                                labelText: "Yaş",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.cake),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v!.isEmpty) return "Zorunlu alan";
                                final age = int.tryParse(v);
                                if (age == null || age < 0 || age > 150) {
                                  return "Geçerli bir yaş giriniz";
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration: const InputDecoration(
                                labelText: "Durum",
                                border: OutlineInputBorder(),
                              ),
                              items: _statuses
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setDialogState(() => _selectedStatus = val!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: "Fiyat (₺)",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.attach_money),
                              ),
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
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("İptal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate() &&
                      _bookingDate != null) {
                    if (reservation == null) {
                      // Yeni rezervasyon ekle
                      await _addReservation(context);
                    } else {
                      // TODO: Update işlemi (şimdilik sadece ekleme var)
                      Navigator.pop(context);
                    }
                  }
                },
                child: Text(reservation != null ? "Güncelle" : "Ekle"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addReservation(BuildContext context) async {
    // UserID'yi al (rezervasyonu yapan müşteri - şimdilik current user)
    final customerUserId = AuthService().currentUserId;
    if (customerUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kullanıcı bilgisi bulunamadı. Lütfen tekrar giriş yapın."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // CreatedByUserID (işlemi yapan admin)
    final createdByUserId = AuthService().currentUserId!;

    // Form verilerini al
    final passengerName = _passengerController.text.trim();
    final passengerParts = passengerName.split(' ');
    final firstName = passengerParts.isNotEmpty ? passengerParts[0] : '';
    final lastName = passengerParts.length > 1 
        ? passengerParts.sublist(1).join(' ') 
        : '';

    if (firstName.isEmpty || lastName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Yolcu adı ve soyadı gereklidir."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // FlightID'yi al (FlightNo'dan - şimdilik direkt sayısal değer olarak kullan)
    final flightNo = _flightNoController.text.trim();
    final flightId = int.tryParse(flightNo.replaceAll(RegExp(r'[^0-9]'), '')) ?? 
                     int.tryParse(flightNo) ?? 0;
    
    if (flightId == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Geçerli bir uçuş numarası giriniz."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // SeatID'yi al (SeatNo'dan - şimdilik direkt sayısal değer olarak kullan)
    final seatNo = _seatNoController.text.trim();
    final seatId = seatNo.isNotEmpty 
        ? int.tryParse(seatNo.replaceAll(RegExp(r'[^0-9]'), ''))
        : null;

    // TotalAmount'u al
    final totalAmount = double.tryParse(_priceController.text.trim()) ?? 0.0;
    if (totalAmount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Geçerli bir fiyat giriniz."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // PassportNo ve Age'yi al
    final passportNo = _passportNoController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 0;

    if (passportNo.isEmpty || age <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pasaport numarası ve yaş gereklidir."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Rezervasyon ekle
    final reservationId = await _adminService.addReservation(
      userId: customerUserId,
      flightId: flightId,
      reservationDate: _bookingDate!,
      status: _selectedStatus,
      totalAmount: totalAmount,
      passengerFirstName: firstName,
      passengerLastName: lastName,
      passportNo: passportNo,
      age: age,
      gender: null,
      nationality: null,
      seatId: seatId,
      boardingGate: null,
      ticketStatus: 'Confirmed',
      createdByUserId: createdByUserId,
    );

    if (mounted) {
      if (reservationId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Rezervasyon başarıyla oluşturuldu. ID: $reservationId"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        // Listeyi yenile
        _loadReservations();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Rezervasyon oluşturulurken bir hata oluştu."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteReservation(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text(
          "Bu rezervasyonu silmek istediğinizden emin misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // UserID'yi al
              final userId = AuthService().currentUserId;
              if (userId == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Kullanıcı bilgisi bulunamadı. Lütfen tekrar giriş yapın."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              // Silme işlemini gerçekleştir
              final success = await _adminService.deleteReservation(
                reservationId: id,
                userId: userId,
              );

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Rezervasyon başarıyla silindi."),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Listeyi yenile
                  _loadReservations();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Rezervasyon silinirken bir hata oluştu."),
                      backgroundColor: Colors.red,
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
    final filtered = _filteredReservations;
    final totalPages = (filtered.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0)
      _currentPage = totalPages - 1;
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = min(startIndex + _itemsPerPage, filtered.length);
    final currentData = filtered.isEmpty
        ? []
        : filtered.sublist(startIndex, endIndex);

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
                    Text(
                      "Rezervasyon Yönetimi",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Rezervasyonları yönetin",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showReservationDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
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
            _isLoading
                ? const Center(
                    child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator()))
                : currentData.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text("Rezervasyon bulunamadı."),
                        ),
                      )
                    : LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 1100
                      ? 3
                      : (constraints.maxWidth > 700 ? 2 : 1);
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
                        key: ValueKey(currentData[index].reservationId ?? index),
                        reservation: currentData[index],
                        onEdit: () => context.go(
                          '/admin/reservations/${currentData[index].reservationId ?? 0}',
                        ),
                        onDelete: () =>
                            _deleteReservation(currentData[index].reservationId ?? 0),
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
                IconButton(
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text("Sayfa ${_currentPage + 1} / $totalPages"),
                IconButton(
                  onPressed: _currentPage < totalPages - 1
                      ? () => setState(() => _currentPage++)
                      : null,
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

// --- REZERVASYON KARTI ---
class _ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReservationCard({
    Key? key,
    required this.reservation,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status) {
      case 'Confirmed':
      case 'Active':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(reservation.reservationStatus);
    final currencyFormat = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 0,
    );

    // Tarih formatla
    String formattedDate = 'N/A';
    if (reservation.reservationDate != null) {
      try {
        final date = DateTime.parse(reservation.reservationDate!);
        formattedDate = DateFormat('dd.MM.yyyy').format(date);
      } catch (e) {
        formattedDate = reservation.reservationDate ?? 'N/A';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5),
        ],
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
                  reservation.passengerName ?? reservation.customerName ?? 'N/A',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  reservation.reservationStatus ?? 'N/A',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 16),

          Row(
            children: [
              const Icon(Icons.flight, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                reservation.flightCode ?? 'N/A',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(Icons.event_seat, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                reservation.seatNumber ?? 'N/A',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                formattedDate,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),

          const Divider(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                reservation.totalAmount != null
                    ? currencyFormat.format(reservation.totalAmount!)
                    : 'N/A',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.teal,
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: onEdit,
                    child: const Icon(Icons.visibility, size: 20, color: Colors.teal),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: onDelete,
                    child: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
