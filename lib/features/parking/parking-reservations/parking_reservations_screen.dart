import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import '../../../core/services/parking_service.dart';
import '../../../core/services/auth_service.dart';

class ParkingReservationsScreen extends StatefulWidget {
  const ParkingReservationsScreen({super.key});

  @override
  State<ParkingReservationsScreen> createState() => _ParkingReservationsScreenState();
}

class _ParkingReservationsScreenState extends State<ParkingReservationsScreen> {
  // --- STATE ---
  final ParkingService _parkingService = ParkingService();
  bool _isLoading = true;
  List<ParkingReservation> _reservations = [];
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
      final reservations = await _parkingService.getReservationList();
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

  // --- FİLTRELEME ---
  List<ParkingReservation> get _filteredReservations {
    return _reservations.where((r) {
      final matchesSearch = r.plateNumber.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          r.customerName.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          r.reservationNo.toLowerCase().contains(_searchTerm.toLowerCase());

      final matchesStatus = _filterStatus == 'all' || r.status == _filterStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  /// ISO tarih string'ini okunabilir formata çevir
  String _formatDateTime(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    } catch (e) {
      return isoString;
    }
  }

  /// Rezervasyon güncelleme işlemini yapar
  Future<void> _handleUpdateReservation(ParkingReservation reservation, BuildContext dialogContext) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // AuthService'den mevcut kullanıcı ID'sini al
    final authService = AuthService();
    final actionUserId = authService.currentUserId;

    if (actionUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı bilgisi bulunamadı. Lütfen tekrar giriş yapın.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Loading göster (root navigator kullan)
    bool loadingDialogShown = false;
    if (mounted) {
      showDialog(
        context: dialogContext,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (loadingContext) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      loadingDialogShown = true;
    }

    try {
      // API'yi çağır
      final success = await _parkingService.updateReservation(
        reservationCode: reservation.reservationNo, // "RES-12" formatında
        plateNumber: _plateController.text.trim(),
        fullName: _customerNameController.text.trim(),
        phone: _phoneController.text.trim(),
        status: _selectedStatus,
        actionUserId: actionUserId,
      );

      // Loading dialog'u kapat (root navigator kullan)
      if (mounted && loadingDialogShown) {
        Navigator.of(dialogContext, rootNavigator: true).pop();
        loadingDialogShown = false;
      }

      if (success) {
        // Form dialog'u kapat (root navigator ile açıldığı için root navigator ile kapat)
        if (mounted) {
          Navigator.of(dialogContext, rootNavigator: true).pop();
        }

        // Başarılı mesajı göster
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rezervasyon başarıyla güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Verileri yeniden yükle
        await _loadReservations();
      } else {
        // Hata mesajı göster (form dialog açık kalır)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rezervasyon güncellenirken bir hata oluştu'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating reservation: $e');
      
      // Loading dialog'u kapat (eğer açıldıysa)
      if (mounted && loadingDialogShown) {
        Navigator.of(dialogContext, rootNavigator: true).pop();
        loadingDialogShown = false;
      }

      // Hata mesajı göster (form dialog açık kalır)
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

  // --- CRUD İŞLEMLERİ ---
  Future<void> _selectDateTime(BuildContext context, TextEditingController controller) async {
    final now = DateTime.now();
    final safeInitialDate = now.isAfter(DateTime(2030, 12, 31))
        ? DateTime(2030, 12, 31)
        : now;
    
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030, 12, 31),
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

  void _showReservationDialog({ParkingReservation? reservation}) {
    if (reservation != null) {
      _plateController.text = reservation.plateNumber;
      _customerNameController.text = reservation.customerName;
      _phoneController.text = reservation.phone;
      _startDateController.text = _formatDateTime(reservation.startTime);
      _endDateController.text = _formatDateTime(reservation.endTime);
      _selectedStatus = reservation.status;
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
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
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
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: reservation != null ? () => _handleUpdateReservation(reservation, dialogContext) : null,
            child: Text(reservation != null ? "Güncelle" : "Oluştur"),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(ParkingReservation reservation) {
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Rezervasyon Detayları"),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow("Rezervasyon No", reservation.reservationNo),
                _DetailRow("Plaka", reservation.plateNumber),
                _DetailRow("Müşteri", reservation.customerName),
                _DetailRow("Telefon", reservation.phone),
                _DetailRow("Park Yeri", reservation.parkingSpot),
                _DetailRow("Başlangıç", _formatDateTime(reservation.startTime)),
                _DetailRow("Bitiş", _formatDateTime(reservation.endTime)),
                _DetailRow("Ödeme Yöntemi", reservation.paymentMethod),
                const Divider(),
                _DetailRow("Tutar", currencyFormat.format(reservation.amount), isBold: true, color: Colors.teal),
                _DetailRow("Durum", reservation.status, isBold: true, color: _getStatusColor(reservation.status)),
              ],
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text("Kapat"),
            ),
          ),
        ],
      ),
    );
  }

  /// Status'a göre renk döndürür
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
      case 'canceled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blue;
    }
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
            _isLoading
                ? const Center(
                    child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator()))
                : currentData.isEmpty
                    ? const Center(
                        child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Text("Rezervasyon bulunamadı.")))
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
                              childAspectRatio: 1.6,
                            ),
                            itemCount: currentData.length,
                            itemBuilder: (context, index) {
                              return _ReservationCard(
                                reservation: currentData[index],
                                onEdit: () => _showReservationDialog(reservation: currentData[index]), // Edit için form dialog
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
  final ParkingReservation reservation;
  final VoidCallback onEdit;
  final VoidCallback onView;

  const _ReservationCard({required this.reservation, required this.onEdit, required this.onView});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
      case 'canceled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _formatDateTime(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(reservation.status);
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reservation.plateNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(reservation.reservationNo,
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(reservation.status,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor)),
              ),
            ],
          ),

          const Divider(height: 16),

          _InfoRow(label: "Müşteri", value: reservation.customerName),
          _InfoRow(label: "Park Yeri", value: reservation.parkingSpot),
          _InfoRow(label: "Başlangıç", value: _formatDateTime(reservation.startTime)),
          _InfoRow(label: "Bitiş", value: _formatDateTime(reservation.endTime)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Tutar:",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text(currencyFormat.format(reservation.amount),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal)),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                  onTap: onView,
                  child: const Icon(Icons.visibility, size: 20, color: Colors.blue)),
              const SizedBox(width: 16),
              InkWell(
                  onTap: onEdit,
                  child: const Icon(Icons.edit, size: 20, color: Colors.orange)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color ?? Colors.black87,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}