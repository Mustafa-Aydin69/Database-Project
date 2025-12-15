import 'package:flutter/material.dart';
import 'dart:math';
import '../../../../core/services/admin_service.dart';
import '../../../../core/services/auth_service.dart';

class ParkingSpotsScreen extends StatefulWidget {
  const ParkingSpotsScreen({super.key});

  @override
  State<ParkingSpotsScreen> createState() => _ParkingSpotsScreenState();
}

class Airport {
  final int id;
  final String name;
  final String city;
  final String iata;

  Airport({
    required this.id,
    required this.name,
    required this.city,
    required this.iata,
  });

  @override
  String toString() => "$iata - $name";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Airport &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          city == other.city &&
          iata == other.iata;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      city.hashCode ^
      iata.hashCode;
}

class _ParkingSpotsScreenState extends State<ParkingSpotsScreen> {
  // --- STATE ---
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<ParkingSpot> _spots = [];
  List<ParkingLot> _parkingLotsList = []; // Tüm otopark alanları (filtreleme için)
  List<Airport> _airportsList = []; // Havalimanları cache (dropdown için)
  int _currentPage = 0;
  final int _itemsPerPage = 12; // Kartlar küçük, sayfada çok gösterebiliriz
  String _searchTerm = "";
  String _filterLot = "";
  String _filterStatus = ""; // "", "available", "reserved"

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  String? _selectedLot;
  Airport? _selectedAirport;

  final TextEditingController _spotNumberController = TextEditingController();
  bool _isReserved = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Tüm verileri yükle (park yerleri + otopark alanları)
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Paralel olarak hem park yerlerini hem otopark alanlarını yükle
      final results = await Future.wait([
        _adminService.getParkingSpots(),
        _adminService.getParkingLots(),
      ]);

      setState(() {
        _spots = results[0] as List<ParkingSpot>;
        _parkingLotsList = results[1] as List<ParkingLot>;
        // Havalimanları listesini güncelle
        _airportsList = _buildAirportsList(_parkingLotsList);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// API'den park yerlerini yükle (sadece park yerleri için - liste yenileme)
  Future<void> _loadParkingSpots() async {
    try {
      final parkingSpots = await _adminService.getParkingSpots();
      setState(() {
        _spots = parkingSpots;
      });
    } catch (e) {
      debugPrint('❌ Error loading parking spots: $e');
    }
  }

  // Otoparklar listesini tüm otopark alanlarından al (dinamik - tüm otoparklar)
  List<String> get _parkingLots {
    final lotList = <String>[];
    for (var lot in _parkingLotsList) {
      if (lot.lotName != null && lot.lotName!.isNotEmpty) {
        lotList.add(lot.lotName!);
      }
    }
    return lotList..sort();
  }

  // Seçilen havalimanına göre otoparkları filtrele (modal için)
  List<String> get _filteredParkingLotsByAirport {
    if (_selectedAirport == null) {
      return _parkingLots; // Havalimanı seçilmemişse tüm otoparklar
    }

    final lotList = <String>[];
    final selectedAirportId = _selectedAirport!.id;
    
    for (var lot in _parkingLotsList) {
      if (lot.lotName != null && 
          lot.lotName!.isNotEmpty &&
          lot.airportId == selectedAirportId) {
        lotList.add(lot.lotName!);
      }
    }
    return lotList..sort();
  }

  // Otopark adından ParkingLotID'yi bul
  int? _getParkingLotIdByName(String? lotName) {
    if (lotName == null || lotName.isEmpty) return null;
    
    for (var lot in _parkingLotsList) {
      if (lot.lotName == lotName) {
        return lot.parkingLotId;
      }
    }
    return null;
  }

  // Havalimanları listesini otopark alanlarından çıkar (dinamik - tüm havalimanları)
  List<Airport> _buildAirportsList(List<ParkingLot> parkingLots) {
    final airportMap = <int, Airport>{}; // AirportID -> Airport (unique için)
    
    for (var lot in parkingLots) {
      if (lot.airportId != null && 
          lot.airportName != null) {
        // Havalimanı zaten eklenmemişse ekle
        if (!airportMap.containsKey(lot.airportId)) {
          // AirportName formatı: "IST - İstanbul Havalimanı" veya sadece "İstanbul Havalimanı"
          String airportName = lot.airportName!;
          String iataCode = lot.airportIATACode ?? '';
          String airportCity = lot.airportCity ?? '';
          
          // Eğer IATA kodu yoksa, AirportName'den çıkarmaya çalış
          if (iataCode.isEmpty) {
            final parts = airportName.split(' - ');
            if (parts.length == 2) {
              iataCode = parts[0].trim();
              airportName = parts[1].trim();
            }
          } else if (airportName.contains(' - ')) {
            // Eğer AirportName formatında IATA varsa ve parse edilmemişse
            final parts = airportName.split(' - ');
            if (parts.length == 2 && parts[0].trim() == iataCode) {
              // IATA kodunu zaten ayrı alan olarak aldık, sadece ismi temizle
              airportName = parts[1].trim();
            }
          }
          
          airportMap[lot.airportId!] = Airport(
            id: lot.airportId!,
            name: airportName,
            city: airportCity,
            iata: iataCode,
          );
        }
      }
    }
    
    // Listeye çevir ve IATA koduna göre sırala
    final airportList = airportMap.values.toList();
    airportList.sort((a, b) {
      // Önce IATA koduna göre sırala, yoksa isme göre
      if (a.iata.isNotEmpty && b.iata.isNotEmpty) {
        return a.iata.compareTo(b.iata);
      }
      return a.name.compareTo(b.name);
    });
    return airportList;
  }

  // Cached havalimanları listesi getter'ı
  List<Airport> get _airports => _airportsList;

  // --- FİLTRELEME ---
  List<ParkingSpot> get _filteredSpots {
    return _spots.where((s) {
      final matchesSearch = (s.spotNumber?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false);
      final matchesLot = _filterLot.isEmpty || s.parkingLotName == _filterLot;

      bool matchesStatus = true;
      if (_filterStatus == 'available') matchesStatus = s.isReserved != true;
      if (_filterStatus == 'reserved') matchesStatus = s.isReserved == true;

      return matchesSearch && matchesLot && matchesStatus;
    }).toList();
  }

  // --- CRUD İŞLEMLERİ ---

  void _showSpotDialog({ParkingSpot? spot}) {
    // Düzenleme modunda olup olmadığımızı kontrol eden değişken
    final bool isEditing = spot != null;

    if (isEditing) {
      final parkingSpot = spot; // isEditing true ise spot null değil
      final int? airportId = parkingSpot.airportId;
      if (airportId != null) {
        try {
          _selectedAirport = _airports.firstWhere((a) => a.id == airportId);
        } catch (e) {
          debugPrint('⚠️ Airport not found in list for ID: $airportId');
          _selectedAirport = null;
        }
      } else {
        _selectedAirport = null;
      }
      _selectedLot = parkingSpot.parkingLotName;
      _spotNumberController.text = parkingSpot.spotNumber ?? '';
      _isReserved = parkingSpot.isReserved ?? false;
    } else {
      _selectedAirport = null;
      _selectedLot = null;
      _spotNumberController.clear();
      _isReserved = false;
    }
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        // Checkbox state'i için StatefulBuilder gerekli
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(isEditing ? 'Park Yeri Düzenle' : 'Yeni Park Yeri'),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- HAVALİMANI (DÜZENLEME MODUNDA KİLİTLİ) ---
                      DropdownButtonFormField<Airport>(
                        value: _selectedAirport != null 
                            ? _airports.firstWhere(
                                (a) => a.id == _selectedAirport!.id,
                                orElse: () => _selectedAirport!,
                              )
                            : null,
                        decoration: InputDecoration(
                          labelText: "Havalimanı",
                          border: const OutlineInputBorder(),
                          filled: isEditing,
                          fillColor: isEditing ? Colors.grey.shade200 : null,
                        ),
                        items: _airports.map((airport) {
                          return DropdownMenuItem<Airport>(
                            value: airport,
                            child: Text("${airport.iata} - ${airport.name}"),
                          );
                        }).toList(),
                        onChanged: isEditing ? null : (val) {
                          if (val != null) {
                            setModalState(() {
                              // Dropdown'dan seçilen Airport objesini kullan (aynı referans)
                              _selectedAirport = val;
                              _selectedLot = null; // Havalimanı değişince otopark seçimini sıfırla
                            });
                          }
                        },
                        validator: (v) =>
                            v == null ? "Havalimanı seçiniz" : null,
                      ),
                      const SizedBox(height: 16),
                      // --- OTOPARK (DÜZENLEME MODUNDA KİLİTLİ, EKLEME MODUNDA HAVALİMANINA GÖRE FİLTRELİ) ---
                      DropdownButtonFormField<String>(
                        value: _selectedLot,
                        decoration: InputDecoration(
                          labelText: "Otopark",
                          border: const OutlineInputBorder(),
                          filled: isEditing || (!isEditing && _selectedAirport == null),
                          fillColor: isEditing || (!isEditing && _selectedAirport == null) 
                              ? Colors.grey.shade200 
                              : null,
                          hintText: !isEditing && _selectedAirport == null 
                              ? "Önce havalimanı seçiniz" 
                              : null,
                        ),
                        items: (isEditing ? _parkingLots : _filteredParkingLotsByAirport)
                            .map(
                              (l) => DropdownMenuItem(value: l, child: Text(l)),
                            )
                            .toList(),
                        onChanged: isEditing || (!isEditing && _selectedAirport == null) 
                            ? null 
                            : (val) {
                                setModalState(() {
                                  _selectedLot = val;
                                });
                              },
                        validator: (v) => v == null ? "Seçiniz" : null,
                      ),
                      const SizedBox(height: 16),
                      // --- PARK YERİ NO (DÜZENLEME MODUNDA KİLİTLİ) ---
                      TextFormField(
                        controller: _spotNumberController,
                        enabled: !isEditing, // Düzenleme modunda değiştirilemez (disabled)
                        decoration: InputDecoration(
                          labelText: "Park Yeri No",
                          border: const OutlineInputBorder(),
                          hintText: "Örn: A-001",
                          filled: isEditing,
                          fillColor: isEditing ? Colors.grey.shade200 : null,
                        ),
                        validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                      ),
                      const SizedBox(height: 16),
                      // --- REZERVE Mİ? (HER ZAMAN DÜZENLENEBİLİR) ---
                      CheckboxListTile(
                        title: const Text("Rezerve mi?"),
                        value: _isReserved,
                        onChanged: (val) =>
                            setModalState(() => _isReserved = val ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
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
                  if (isEditing) {
                    // Sadece IsReserved değişikliği için validasyon yok, direkt güncelleme yap
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

                    final parkingSpot = spot; // isEditing true ise spot null değil

                    // Loading dialog göster
                    if (mounted) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (loadingContext) => const Center(child: CircularProgressIndicator()),
                      );
                    }

                    try {
                      final success = await _adminService.updateParkingSpot(
                        spotId: parkingSpot.spotId!,
                        isReserved: _isReserved,
                        userId: userId,
                      );

                      // Loading dialog'u kapat
                      if (mounted) {
                        Navigator.of(context, rootNavigator: true).pop();
                      }

                      if (success) {
                        // Dialog'u kapat
                        Navigator.pop(context);
                        // Başarılı mesajı göster
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Park yeri başarıyla güncellendi"),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Listeyi yenile
                        _loadParkingSpots();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Park yeri güncellenirken bir hata oluştu"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      // Loading dialog'u kapat
                      if (mounted) {
                        Navigator.of(context, rootNavigator: true).pop();
                      }
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Hata: ${e.toString()}"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    // Yeni ekleme modu
                    if (_formKey.currentState!.validate()) {
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

                      // Seçilen otopark adından ParkingLotID'yi bul
                      final parkingLotId = _getParkingLotIdByName(_selectedLot);
                      if (parkingLotId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Otopark bilgisi bulunamadı. Lütfen geçerli bir otopark seçin."),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (_spotNumberController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Park yeri numarası boş olamaz"),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Loading dialog göster
                      if (mounted) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (loadingContext) => const Center(child: CircularProgressIndicator()),
                        );
                      }

                      try {
                        final result = await _adminService.addParkingSpot(
                          parkingLotId: parkingLotId,
                          spotNumber: _spotNumberController.text.trim(),
                          isReserved: _isReserved,
                          userId: userId,
                        );

                        // Loading dialog'u kapat
                        if (mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }

                        if (result['success'] == true) {
                          // Dialog'u kapat
                          Navigator.pop(context);
                          // Başarılı mesajı göster
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Park yeri başarıyla eklendi"),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Listeyi yenile
                          _loadParkingSpots();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? 'Park yeri eklenirken bir hata oluştu'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        // Loading dialog'u kapat
                        if (mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }
                        
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
                child: Text(isEditing ? "Güncelle" : "Ekle"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteSpot(int id) async {
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

    // Onay modalı göster
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text(
          "Bu park yerini silmek istediğinizden emin misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return; // Kullanıcı iptal etti
    }

    // Loading dialog göster
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (loadingContext) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final success = await _adminService.deleteParkingSpot(
        spotId: id,
        userId: userId,
      );

      // Loading dialog'u kapat
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (success) {
        // Başarılı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Park yeri başarıyla silindi"),
            backgroundColor: Colors.green,
          ),
        );
        // Listeyi yenile
        _loadParkingSpots();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Park yeri silinirken bir hata oluştu"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Loading dialog'u kapat
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleStatus(int id) async {
    // Park yerini bul
    ParkingSpot? spot;
    try {
      spot = _spots.firstWhere((s) => s.spotId == id);
    } catch (e) {
      // Park yeri bulunamadı
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Park yeri bulunamadı"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Yeni durum
    final newStatus = !(spot.isReserved ?? false);

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
        context: context,
        barrierDismissible: false,
        builder: (loadingContext) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final success = await _adminService.updateParkingSpot(
        spotId: id,
        isReserved: newStatus,
        userId: userId,
      );

      // Loading dialog'u kapat
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (success) {
        // Başarılı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? "Park yeri rezerve edildi" : "Park yeri rezervasyonu kaldırıldı"),
            backgroundColor: Colors.green,
          ),
        );
        // Listeyi yenile
        _loadParkingSpots();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Park yeri durumu güncellenirken bir hata oluştu"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Loading dialog'u kapat
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final filtered = _filteredSpots;
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
                      "Park Yerleri",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Otopark alanlarındaki bireysel park yerlerini yönetin",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showSpotDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Yeni Park Yeri"),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- FİLTRELER ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 800;
                  return Flex(
                    direction: isMobile ? Axis.vertical : Axis.horizontal,
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchTerm = val),
                          decoration: const InputDecoration(
                            hintText: "Park yeri ara...",
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: isMobile ? 0 : 16,
                        height: isMobile ? 16 : 0,
                      ),
                      SizedBox(
                        width: isMobile ? double.infinity : 250,
                        child: DropdownButtonFormField<String>(
                          value: _filterLot.isEmpty ? null : _filterLot,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            hintText: "Tüm Otoparklar",
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: "",
                              child: Text("Tüm Otoparklar"),
                            ),
                            ..._parkingLots.map(
                              (l) => DropdownMenuItem(value: l, child: Text(l)),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _filterLot = val ?? ""),
                        ),
                      ),
                      SizedBox(
                        width: isMobile ? 0 : 16,
                        height: isMobile ? 16 : 0,
                      ),
                      SizedBox(
                        width: isMobile ? double.infinity : 200,
                        child: DropdownButtonFormField<String>(
                          value: _filterStatus.isEmpty ? null : _filterStatus,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            hintText: "Tüm Durumlar",
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: "",
                              child: Text("Tüm Durumlar"),
                            ),
                            DropdownMenuItem(
                              value: "available",
                              child: Text("Müsait"),
                            ),
                            DropdownMenuItem(
                              value: "reserved",
                              child: Text("Rezerve"),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _filterStatus = val ?? ""),
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
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text("Park yeri bulunamadı."),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  // Park yeri kartları çok küçük, 4-5 sütun olabilir
                  int crossAxisCount = constraints.maxWidth > 1100
                      ? 4
                      : (constraints.maxWidth > 700 ? 3 : 2);
                  // Mobilde çok küçük olmasın diye min 2
                  if (constraints.maxWidth < 500) crossAxisCount = 1;

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
                      return _ParkingSpotCard(
                        spot: currentData[index],
                        onEdit: () => _showSpotDialog(spot: currentData[index]),
                        onDelete: () =>
                            _deleteSpot(currentData[index].spotId ?? 0),
                        onToggleStatus: () =>
                            _toggleStatus(currentData[index].spotId ?? 0),
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

// --- PARK YERİ KARTI ---
class _ParkingSpotCard extends StatelessWidget {
  final ParkingSpot spot;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const _ParkingSpotCard({
    required this.spot,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final bool isReserved = spot.isReserved ?? false;
    final Color statusColor = isReserved ? Colors.red : Colors.green;
    final String statusText = isReserved ? 'Rezerve' : 'Müsait';

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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                spot.spotNumber ?? 'N/A',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              InkWell(
                onTap: onToggleStatus,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 12),

          Row(
            children: [
              const Icon(Icons.local_parking, size: 16, color: Colors.blue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  spot.parkingLotName ?? 'N/A',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(Icons.flight, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  spot.airportDisplayName ?? spot.airportName ?? 'N/A',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: onEdit,
                child: const Icon(Icons.edit, size: 18, color: Colors.teal),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: onDelete,
                child: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
