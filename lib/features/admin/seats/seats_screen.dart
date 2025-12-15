import 'package:flutter/material.dart';
import 'dart:math';
import '../../../core/services/admin_service.dart';
import '../../../core/services/auth_service.dart';

class SeatsScreen extends StatefulWidget {
  const SeatsScreen({super.key});

  @override
  State<SeatsScreen> createState() => _SeatsScreenState();
}

class _SeatsScreenState extends State<SeatsScreen> {
  // --- STATE ---
  int _currentPage = 0;
  final int _itemsPerPage =
      12; // Koltuklar küçük olduğu için sayfada daha çok gösterebiliriz
  String _searchTerm = "";
  String _filterAircraft = "";
  bool _isLoading = true;
  final AdminService _adminService = AdminService();

  // --- FORM KONTROLCÜLERİ ---
  final _formKey = GlobalKey<FormState>(); // Tekli Ekleme Formu
  final _bulkFormKey = GlobalKey<FormState>(); // Toplu Ekleme Formu

  // Tekli Ekleme Değişkenleri
  String? _selectedAircraft;
  String? _selectedClass;
  final TextEditingController _seatNumController = TextEditingController();

  // Toplu Ekleme Değişkenleri
  String? _bulkAircraft;
  String? _bulkClass;
  final TextEditingController _startRowController = TextEditingController(
    text: "1",
  );
  final TextEditingController _endRowController = TextEditingController(
    text: "30",
  );
  final TextEditingController _seatLettersController = TextEditingController(
    text: "A,B,C,D,E,F",
  );

  // --- VERİLER ---
  List<Seat> _seats = [];

  // --- LIFECYCLE ---
  @override
  void initState() {
    super.initState();
    _loadSeats();
  }

  // --- VERİ YÜKLEME ---
  Future<void> _loadSeats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final seats = await _adminService.getSeats();
      if (mounted) {
        setState(() {
          _seats = seats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading seats: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Koltuklar yüklenirken hata oluştu: ${e.toString()}')),
        );
      }
    }
  }

  // Dinamik Listeler (veritabanından gelen verilerden oluşturulur)
  List<String> get _aircraftOptions {
    final models = _seats.map((s) => s.aircraftModel ?? '').where((m) => m.isNotEmpty).toSet().toList();
    models.sort();
    return models;
  }

  List<String> get _classOptions {
    final classes = _seats.map((s) => s.className ?? '').where((c) => c.isNotEmpty).toSet().toList();
    classes.sort();
    return classes;
  }

  // --- FİLTRELEME ---
  List<Seat> get _filteredSeats {
    return _seats.where((seat) {
      final matchesSearch =
          (seat.seatNumber?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false) ||
          (seat.aircraftModel?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false);
      final matchesFilter =
          _filterAircraft.isEmpty || seat.aircraftModel == _filterAircraft;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  // --- CRUD İŞLEMLERİ ---

  // 1. TEKLİ EKLEME / DÜZENLEME MODALI
  void _showSeatDialog({Seat? seat}) {
    if (seat != null) {
      // Düzenleme modu: Sadece class değiştirilebilir
      _selectedClass = seat.className;
    } else {
      // Ekleme modu: Tüm alanlar editable
      _selectedAircraft = null;
      _selectedClass = null;
      _seatNumController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(seat != null ? 'Koltuk Düzenle' : 'Yeni Koltuk'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Düzenleme modunda: Uçak modeli readonly
                  if (seat != null)
                    TextFormField(
                      initialValue: seat.aircraftModel ?? '',
                      decoration: const InputDecoration(
                        labelText: "Uçak Modeli",
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey,
                      ),
                      enabled: false,
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedAircraft,
                      decoration: const InputDecoration(
                        labelText: "Uçak Modeli",
                        border: OutlineInputBorder(),
                      ),
                      items: _aircraftOptions
                          .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedAircraft = val),
                      validator: (v) => v == null ? "Seçiniz" : null,
                    ),
                  const SizedBox(height: 16),
                  // Düzenleme modunda: Koltuk numarası readonly
                  if (seat != null)
                    TextFormField(
                      initialValue: seat.seatNumber ?? '',
                      decoration: const InputDecoration(
                        labelText: "Koltuk No",
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey,
                      ),
                      enabled: false,
                    )
                  else
                    TextFormField(
                      controller: _seatNumController,
                      decoration: const InputDecoration(
                        labelText: "Koltuk No (Örn: 12A)",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Gerekli" : null,
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedClass,
                    decoration: const InputDecoration(
                      labelText: "Sınıf",
                      border: OutlineInputBorder(),
                    ),
                    items: _classOptions
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedClass = val),
                    validator: (v) => v == null ? "Seçiniz" : null,
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
            onPressed: seat != null ? () async {
              // Düzenleme modu
              if (_formKey.currentState!.validate()) {
                // Loading dialog göster
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  final userId = AuthService().currentUserId;
                  if (userId == null) {
                    if (mounted) {
                      Navigator.of(context, rootNavigator: true).pop(); // Loading dialog'u kapat
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kullanıcı ID alınamadı. Lütfen tekrar giriş yapın.')),
                      );
                    }
                    return;
                  }

                  await _adminService.updateSeat(
                    seatId: seat.seatID!,
                    className: _selectedClass ?? '',
                    userId: userId,
                  );

                  if (mounted) {
                    Navigator.of(context, rootNavigator: true).pop(); // Loading dialog'u kapat
                    Navigator.pop(context); // Modal'ı kapat
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Koltuk başarıyla güncellendi.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Koltuk listesini yenile
                    _loadSeats();
                  }
                } catch (e) {
                  debugPrint('❌ Error updating seat: $e');
                  if (mounted) {
                    Navigator.of(context, rootNavigator: true).pop(); // Loading dialog'u kapat
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            } : () async {
              // Ekleme modu
              if (_formKey.currentState!.validate()) {
                // Loading dialog göster
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  final userId = AuthService().currentUserId;
                  if (userId == null) {
                    if (mounted) {
                      Navigator.of(context, rootNavigator: true).pop(); // Loading dialog'u kapat
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kullanıcı ID alınamadı. Lütfen tekrar giriş yapın.')),
                      );
                    }
                    return;
                  }

                  await _adminService.addSeat(
                    aircraftModel: _selectedAircraft ?? '',
                    seatNumber: _seatNumController.text.trim(),
                    className: _selectedClass ?? '',
                    userId: userId,
                  );

                  if (mounted) {
                    Navigator.of(context, rootNavigator: true).pop(); // Loading dialog'u kapat
                    Navigator.pop(context); // Modal'ı kapat
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Koltuk başarıyla eklendi.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Koltuk listesini yenile
                    _loadSeats();
                  }
                } catch (e) {
                  debugPrint('❌ Error adding seat: $e');
                  if (mounted) {
                    Navigator.of(context, rootNavigator: true).pop(); // Loading dialog'u kapat
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(seat != null ? "Güncelle" : "Ekle"),
          ),
        ],
      ),
    );
  }

  // 2. TOPLU EKLEME MODALI
  void _showBulkDialog() {
    _bulkAircraft = null;
    _bulkClass = null;
    // Controllerlar varsayılan değerlerinde kalsın (1-30, A-F)

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Toplu Koltuk Oluştur'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: _bulkFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _bulkAircraft,
                    decoration: const InputDecoration(
                      labelText: "Uçak Modeli",
                      border: OutlineInputBorder(),
                    ),
                    items: _aircraftOptions
                        .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                        .toList(),
                    onChanged: (val) => setState(() => _bulkAircraft = val),
                    validator: (v) => v == null ? "Seçiniz" : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _bulkClass,
                    decoration: const InputDecoration(
                      labelText: "Sınıf",
                      border: OutlineInputBorder(),
                    ),
                    items: _classOptions
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setState(() => _bulkClass = val),
                    validator: (v) => v == null ? "Seçiniz" : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _startRowController,
                          decoration: const InputDecoration(
                            labelText: "Başlangıç Sıra",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? "Gerekli" : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _endRowController,
                          decoration: const InputDecoration(
                            labelText: "Bitiş Sıra",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? "Gerekli" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _seatLettersController,
                    decoration: const InputDecoration(
                      labelText: "Koltuk Harfleri (virgülle ayırın)",
                      hintText: "A,B,C,D,E,F",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Gerekli" : null,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Örnek: Sıra 1-30, Koltuklar A-F",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
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
            onPressed: () {
              if (_bulkFormKey.currentState!.validate()) {
                // TODO: Bulk Add API entegrasyonu eklenecek
                Navigator.pop(context);
              }
            },
            child: const Text("Oluştur"),
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

    // Sayfalama
    final filtered = _filteredSeats;
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
                      "Koltuk Yönetimi",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Uçak koltukları ve yerleşim planları",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Toplu Oluştur butonu ve SizedBox kaldırıldı
                    ElevatedButton.icon(
                      onPressed: () => _showSeatDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text("Yeni Koltuk"),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- ARAMA VE FİLTRE ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      onChanged: (val) => setState(() => _searchTerm = val),
                      decoration: const InputDecoration(
                        hintText: "Koltuk numarası veya uçak ara...",
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _filterAircraft.isEmpty ? null : _filterAircraft,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
                        hintText: "Tüm Uçaklar",
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: "",
                          child: Text("Tüm Uçaklar"),
                        ),
                        ..._aircraftOptions.map(
                          (a) => DropdownMenuItem(value: a, child: Text(a)),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _filterAircraft = val ?? ""),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- KART LİSTESİ ---
            if (currentData.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text("Koltuk bulunamadı."),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  // Koltuklar küçük olduğu için daha fazla sütun
                  int crossAxisCount = constraints.maxWidth > 1100
                      ? 4
                      : (constraints.maxWidth > 700 ? 2 : 1);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: currentData.length,
                    itemBuilder: (context, index) {
                      return _SeatCard(
                        seat: currentData[index],
                        onEdit: () => _showSeatDialog(seat: currentData[index]),
                      );
                    },
                  );
                },
              ),

            const SizedBox(height: 24),

            // --- SAYFALAMA ---
            if (totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text("Sayfa ${_currentPage + 1} / $totalPages"),
                  ),
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

// --- KOLTUK KARTI ---
class _SeatCard extends StatelessWidget {
  final Seat seat;
  final VoidCallback onEdit;

  const _SeatCard({
    required this.seat,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  seat.aircraftModel ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  seat.seatNumber ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
              ),
            ],
          ),

          Text(
            seat.className ?? '',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: onEdit,
                child: Icon(Icons.edit, size: 18, color: Colors.teal.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
