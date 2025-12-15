import 'package:flutter/material.dart';
import 'dart:math';
import '../../../core/services/admin_service.dart';
import '../../../core/services/auth_service.dart';

class PassengersScreen extends StatefulWidget {
  const PassengersScreen({super.key});

  @override
  State<PassengersScreen> createState() => _PassengersScreenState();
}

class _PassengersScreenState extends State<PassengersScreen> {
  // --- STATE ---
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<Passenger> _passengers = [];
  List<Reservation> _reservations = [];
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
  final TextEditingController _ageController = TextEditingController();
  String? _selectedGender;
  int? _selectedReservationId;

  @override
  void initState() {
    super.initState();
    _loadPassengers();
    _loadReservations();
  }

  /// API'den rezervasyonları yükle (dropdown için)
  Future<void> _loadReservations() async {
    try {
      final reservations = await _adminService.getReservations();
      setState(() {
        _reservations = reservations;
      });
    } catch (e) {
      debugPrint('❌ Error loading reservations: $e');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passportController.dispose();
    _nationalityController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  /// API'den yolcuları yükle
  Future<void> _loadPassengers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final passengers = await _adminService.getPassengers();
      setState(() {
        _passengers = passengers;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading passengers: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- CRUD İŞLEMLERİ ---

  void _showPassengerDialog({Passenger? passenger}) {
    if (passenger != null) {
      _firstNameController.text = passenger.firstName ?? '';
      _lastNameController.text = passenger.lastName ?? '';
      _emailController.text = passenger.customerEmail ?? '';
      _phoneController.text = passenger.customerPhone ?? '';
      _passportController.text = passenger.passportNo ?? '';
      _nationalityController.text = passenger.nationality ?? '';
      _ageController.text = passenger.age?.toString() ?? '';
      _selectedGender = passenger.gender;
    } else {
      _firstNameController.clear();
      _lastNameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _passportController.clear();
      _nationalityController.clear();
      _ageController.clear();
      _selectedGender = null;
      _selectedReservationId = null;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                  // Yeni yolcu ekleme durumunda ReservationID dropdown göster
                  if (passenger == null) ...[
                    DropdownButtonFormField<int>(
                      value: _selectedReservationId,
                      decoration: const InputDecoration(
                        labelText: "Rezervasyon",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.confirmation_number),
                      ),
                      items: _reservations.map((reservation) {
                        return DropdownMenuItem<int>(
                          value: reservation.reservationId,
                          child: Text(
                            '${reservation.reservationCode ?? 'Rezervasyon #${reservation.reservationId}'} - ${reservation.departureAirport ?? ''} → ${reservation.arrivalAirport ?? ''}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setDialogState(() => _selectedReservationId = val),
                      validator: (v) => v == null ? "Zorunlu" : null,
                    ),
                    const SizedBox(height: 16),
                  ],
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
                  // E-posta ve Telefon alanları sadece düzenleme modunda göster (yeni ekleme için gerekli değil)
                  if (passenger != null) ...[
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: "E-posta", border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: "Telefon", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _passportController,
                          decoration: const InputDecoration(labelText: "Pasaport No", border: OutlineInputBorder(), prefixIcon: Icon(Icons.book)),
                          validator: (v) => v!.isEmpty ? "Zorunlu" : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          decoration: const InputDecoration(labelText: "Yaş", border: OutlineInputBorder(), prefixIcon: Icon(Icons.cake)),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v!.isEmpty) return "Zorunlu";
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
                        child: TextFormField(
                          controller: _nationalityController,
                          decoration: const InputDecoration(labelText: "Uyruk", border: OutlineInputBorder(), prefixIcon: Icon(Icons.flag)),
                          validator: (v) => v!.isEmpty ? "Zorunlu" : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: const InputDecoration(labelText: "Cinsiyet", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                          items: const [
                            DropdownMenuItem(value: 'Male', child: Text('Erkek')),
                            DropdownMenuItem(value: 'Female', child: Text('Kadın')),
                          ],
                          onChanged: (val) => setDialogState(() => _selectedGender = val),
                          validator: (v) => v == null ? "Zorunlu" : null,
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
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  if (passenger != null) {
                    // Güncelleme işlemi
                    final userId = AuthService().currentUserId;
                    if (userId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Kullanıcı kimliği bulunamadı. Lütfen tekrar giriş yapın."),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Loading dialog göster
                    if (mounted) {
                      showDialog(
                        context: dialogContext,
                        barrierDismissible: false,
                        builder: (loadingContext) => const Center(child: CircularProgressIndicator()),
                      );
                    }

                    try {
                      final success = await _adminService.updatePassenger(
                        passengerId: passenger.passengerId!,
                        firstName: _firstNameController.text.trim(),
                        lastName: _lastNameController.text.trim(),
                        passportNo: _passportController.text.trim(),
                        age: _ageController.text.trim().isEmpty ? null : int.tryParse(_ageController.text.trim()),
                        gender: _selectedGender,
                        nationality: _nationalityController.text.trim().isEmpty ? null : _nationalityController.text.trim(),
                        userId: userId,
                      );

                      // Loading dialog'u kapat
                      if (mounted) Navigator.pop(dialogContext);

                      if (success) {
                        // Dialog'u kapat
                        Navigator.pop(context);
                        // Başarılı mesajı göster
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Yolcu bilgileri başarıyla güncellendi"),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Listeyi yenile
                        _loadPassengers();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Yolcu güncellenirken bir hata oluştu"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      // Loading dialog'u kapat
                      if (mounted) Navigator.pop(dialogContext);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Hata: ${e.toString()}"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    // Ekleme işlemi
                    final userId = AuthService().currentUserId;
                    if (userId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Kullanıcı kimliği bulunamadı. Lütfen tekrar giriş yapın."),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (_selectedReservationId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Lütfen bir rezervasyon seçin."),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Loading dialog göster
                    if (mounted) {
                      showDialog(
                        context: dialogContext,
                        barrierDismissible: false,
                        builder: (loadingContext) => const Center(child: CircularProgressIndicator()),
                      );
                    }

                    try {
                      final passengerId = await _adminService.addPassenger(
                        reservationId: _selectedReservationId!,
                        firstName: _firstNameController.text.trim(),
                        lastName: _lastNameController.text.trim(),
                        passportNo: _passportController.text.trim(),
                        age: _ageController.text.trim().isEmpty ? null : int.tryParse(_ageController.text.trim()),
                        gender: _selectedGender,
                        nationality: _nationalityController.text.trim().isEmpty ? null : _nationalityController.text.trim(),
                        userId: userId,
                      );

                      // Loading dialog'u kapat
                      if (mounted) Navigator.pop(dialogContext);

                      if (passengerId != null) {
                        // Dialog'u kapat
                        Navigator.pop(context);
                        // Başarılı mesajı göster
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Yeni yolcu başarıyla eklendi"),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Listeyi yenile
                        _loadPassengers();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Yolcu eklenirken bir hata oluştu"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      // Loading dialog'u kapat
                      if (mounted) Navigator.pop(dialogContext);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Hata: ${e.toString()}"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: Text(passenger != null ? "Güncelle" : "Ekle"),
            ),
          ],
        ),
      ),
    );
  }

  void _deletePassenger(int id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Bu yolcuyu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () async {
              // Dialog'u kapat
              Navigator.pop(dialogContext);

              // Kullanıcı ID'sini al
              final userId = AuthService().currentUserId;
              if (userId == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Kullanıcı kimliği bulunamadı. Lütfen tekrar giriş yapın."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              // Loading dialog göster
              if (!mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingDialogContext) => const Center(child: CircularProgressIndicator()),
              );

              try {
                final success = await _adminService.deletePassenger(
                  passengerId: id,
                  userId: userId,
                );

                // Loading dialog'u kapat
                if (mounted) {
                  Navigator.of(context, rootNavigator: true).pop();
                }

                if (success) {
                  // Başarılı mesajı göster
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Yolcu başarıyla silindi"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                  // Listeyi yenile
                  if (mounted) {
                    _loadPassengers();
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Yolcu silinirken bir hata oluştu"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                // Loading dialog'u kapat
                if (mounted) {
                  Navigator.of(context, rootNavigator: true).pop();
                }
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Hata: ${e.toString()}"),
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
                        onDelete: () => _deletePassenger(currentData[index].passengerId ?? 0),
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
  final Passenger passenger;
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${passenger.firstName ?? ''} ${passenger.lastName ?? ''}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text("ID: ${passenger.passengerId ?? 'N/A'}", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    if (passenger.reservationCode != null)
                      Text("Rezervasyon: ${passenger.reservationCode}", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  passenger.nationality ?? 'N/A',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                ),
              ),
            ],
          ),

          const Divider(height: 16),

          if (passenger.customerEmail != null)
            _InfoItem(icon: Icons.email_outlined, text: passenger.customerEmail!),
          if (passenger.customerPhone != null) ...[
            if (passenger.customerEmail != null) const SizedBox(height: 4),
            _InfoItem(icon: Icons.phone_outlined, text: passenger.customerPhone!),
          ],
          if (passenger.passportNo != null) ...[
            if (passenger.customerPhone != null) const SizedBox(height: 4),
            _InfoItem(icon: Icons.book_outlined, text: passenger.passportNo!),
          ],
          if (passenger.age != null && passenger.gender != null) ...[
            if (passenger.passportNo != null) const SizedBox(height: 4),
            _InfoItem(icon: Icons.person_outline, text: "${passenger.age} yaş, ${passenger.gender == 'Male' ? 'Erkek' : 'Kadın'}"),
          ],

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