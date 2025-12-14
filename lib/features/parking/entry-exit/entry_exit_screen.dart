import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'models/currently_parked_vehicle_model.dart';
import 'services/currently_parked_api.dart';
import 'models/exit_vehicle_model.dart';
import 'services/recent_exits_api.dart';
import 'models/exit_popup_info_model.dart';
import 'services/parking_api_service.dart';
import 'models/exit_panel_card.dart';
import 'services/exit_panel_cards_api.dart';

class EntryExitScreen extends StatefulWidget {
  const EntryExitScreen({super.key});

  @override
  State<EntryExitScreen> createState() => _EntryExitScreenState();
}

class _EntryExitScreenState extends State<EntryExitScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Future<List<CurrentlyParkedVehicleModel>>? _parkedFuture;
  Future<List<ExitPanelCard>>? _recentExitsFuture;

  // --- MOCK VERİLER ---
  List<Map<String, dynamic>> _parkedVehicles = [
    {
      'id': '1', 'plate': '34 ABC 123', 'vehicleType': 'Otomobil', 'ownerName': 'Ahmet Yılmaz',
      'ownerPhone': '0532 123 4567', 'entryTime': '2024-01-15 08:30', 'spotNumber': 'A-15',
      'block': 'A', 'airportName': 'İstanbul Havalimanı (IST)', 'parkingLotName': 'A Terminali Otopark',
      'status': 'parked'
    },
    {
      'id': '2', 'plate': '06 XYZ 789', 'vehicleType': 'SUV', 'ownerName': 'Ayşe Demir',
      'ownerPhone': '0533 987 6543', 'entryTime': '2024-01-15 09:15', 'spotNumber': 'B-23',
      'block': 'B', 'airportName': 'İstanbul Havalimanı (IST)', 'parkingLotName': 'A Terminali Otopark',
      'status': 'parked'
    },
    {
      'id': '3', 'plate': '35 DEF 456', 'vehicleType': 'Minivan', 'ownerName': 'Mehmet Kaya',
      'ownerPhone': '0534 555 1234', 'entryTime': '2024-01-15 10:00', 'spotNumber': 'C-08',
      'block': 'C', 'airportName': 'Sabiha Gökçen (SAW)', 'parkingLotName': 'Açık Otopark',
      'status': 'parked'
    },
  ];

  List<Map<String, dynamic>> _recentExits = [
    {
      'id': '6', 'plate': '34 MNO 987', 'vehicleType': 'Otomobil', 'ownerName': 'Zeynep Arslan',
      'ownerPhone': '0537 222 1357', 'entryTime': '2024-01-15 07:00', 'spotNumber': 'B-12',
      'block': 'B', 'airportName': 'İstanbul Havalimanı (IST)', 'parkingLotName': 'A Terminali Otopark',
      'status': 'exited'
    },
  ];

  // Form Kontrolcüleri
  final _entryFormKey = GlobalKey<FormState>();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _spotController = TextEditingController();
  String _selectedVehicleType = 'Otomobil';
  String _selectedAirport = 'İstanbul Havalimanı (IST)';

  final List<String> _vehicleTypes = ['Otomobil', 'SUV', 'Minivan', 'Pickup', 'Motosiklet'];
  final List<String> _airports = ['İstanbul Havalimanı (IST)', 'Sabiha Gökçen (SAW)', 'Antalya Havalimanı (AYT)', 'Esenboğa (ESB)'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadParked();
    _loadRecentExits();
  }

  void _loadParked() {
    setState(() {
      _parkedFuture = CurrentlyParkedApi.fetchCurrentlyParked();
    });
  }

  void _loadRecentExits() {
    setState(() {
      _recentExitsFuture = ExitPanelCardsApi.fetch();
    });
  }

  String _formatTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  // --- GİRİŞ İŞLEMİ ---
  void _showEntryDialog() {
    _plateController.clear();
    _ownerNameController.clear();
    _phoneController.clear();
    _spotController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Araç Girişi'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: _entryFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _plateController,
                    decoration: const InputDecoration(labelText: "Plaka", border: OutlineInputBorder(), hintText: "34 ABC 123"),
                    validator: (v) => v!.isEmpty ? "Zorunlu" : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedVehicleType,
                    decoration: const InputDecoration(labelText: "Araç Tipi", border: OutlineInputBorder()),
                    items: _vehicleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setState(() => _selectedVehicleType = val!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ownerNameController,
                    decoration: const InputDecoration(labelText: "Araç Sahibi", border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? "Zorunlu" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: "Telefon", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedAirport,
                    decoration: const InputDecoration(labelText: "Havalimanı", border: OutlineInputBorder()),
                    items: _airports.map((a) => DropdownMenuItem(value: a, child: Text(a, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) => setState(() => _selectedAirport = val!),
                    isExpanded: true,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _spotController,
                    decoration: const InputDecoration(labelText: "Park Yeri No", border: OutlineInputBorder()),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () {
              if (_entryFormKey.currentState!.validate()) {
                setState(() {
                  _parkedVehicles.insert(0, {
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'plate': _plateController.text,
                    'vehicleType': _selectedVehicleType,
                    'ownerName': _ownerNameController.text,
                    'ownerPhone': _phoneController.text,
                    'entryTime': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                    'spotNumber': _spotController.text,
                    'airportName': _selectedAirport,
                    'parkingLotName': 'A Terminali Otopark', // Varsayılan
                    'status': 'parked'
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Giriş Yap"),
          ),
        ],
      ),
    );
  }

  // --- ÇIKIŞ İŞLEMİ (Hesaplama) ---
  void _showExitDialog(Map<String, dynamic> vehicle) {
    final plate = vehicle['plate'] as String;
    Future<ExitPopupInfo> popupFuture = ParkingApiService.getExitPopupInfo(plate);

    String? selectedPayment;

    ExitPopupInfo? infoRef;
    bool isCheckingOut = false;
    String? checkoutError;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Araç Çıkışı"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<ExitPopupInfo>(
                  future: popupFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    if (snapshot.hasError) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(snapshot.error.toString(), style: TextStyle(color: Colors.red.shade700)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              setStateDialog(() {
                                popupFuture = ParkingApiService.getExitPopupInfo(plate);
                              });
                            },
                            child: const Text("Tekrar Dene"),
                          )
                        ],
                      );
                    }
                    final info = snapshot.data!;
                    infoRef = info;
                    final entryTimeStr = DateFormat('HH:mm').format(info.checkInTime);
                    final mins = info.durationMinutes;
                    final durStr = mins < 60
                        ? "${mins}Ydk"
                        : "${(mins ~/ 60)}s ${(mins % 60)}Ydk";
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(label: "Plaka", value: info.plateNumber),
                        _InfoRow(label: "Sahibi", value: info.ownerName),
                        _InfoRow(label: "Giriş Saati", value: entryTimeStr),
                        const Divider(),
                        _InfoRow(label: "Kalış Süresi", value: durStr, isBold: true),
                        _InfoRow(label: "Ödeme Tutarı", value: "₺${info.amount.toStringAsFixed(2)}", isBold: true, valueColor: Colors.green),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text("Ödeme Yöntemi", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title: const Text("Nakit"),
                  value: "Nakit",
                  groupValue: selectedPayment,
                  onChanged: (val) => setStateDialog(() => selectedPayment = val),
                ),
                RadioListTile<String>(
                  title: const Text("Kart"),
                  value: "Kart",
                  groupValue: selectedPayment,
                  onChanged: (val) => setStateDialog(() => selectedPayment = val),
                ),
                if (checkoutError != null) ...[
                  const SizedBox(height: 8),
                  Text(checkoutError!, style: TextStyle(color: Colors.red.shade700)),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      if (infoRef == null || selectedPayment == null) return;
                      setStateDialog(() {
                        checkoutError = null;
                        isCheckingOut = true;
                      });
                      try {
                        await ParkingApiService.checkoutVehicle(
                          plateNumber: infoRef!.plateNumber,
                          amount: infoRef!.amount,
                          paymentMethod: selectedPayment!,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        _loadParked();
                        _loadRecentExits();
                      } catch (e) {
                        setStateDialog(() {
                          checkoutError = e.toString();
                        });
                      } finally {
                        setStateDialog(() {
                          isCheckingOut = false;
                        });
                      }
                    },
                    child: const Text("Tekrar Dene"),
                  )
                ]
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: isCheckingOut
                    ? null
                    : () async {
                        if (selectedPayment == null || infoRef == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Ödeme yöntemi ve bilgi yüklemesi gerekli"), backgroundColor: Colors.orange),
                          );
                          return;
                        }
                        setStateDialog(() {
                          checkoutError = null;
                          isCheckingOut = true;
                        });
                        try {
                          await ParkingApiService.checkoutVehicle(
                            plateNumber: infoRef!.plateNumber,
                            amount: infoRef!.amount,
                            paymentMethod: selectedPayment!,
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          _loadParked();
                          _loadRecentExits();
                        } catch (e) {
                          setStateDialog(() {
                            checkoutError = e.toString();
                          });
                        } finally {
                          setStateDialog(() {
                            isCheckingOut = false;
                          });
                        }
                      },
                child: isCheckingOut
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text("Çıkış Yap"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // --- HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Araç Giriş/Çıkış", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text("Araç giriş ve çıkış işlemlerini yönetin", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showEntryDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Yeni Araç Girişi"),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- TAB BAR ---
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.orange,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.orange,
                tabs: const [
                  Tab(text: "Park Halindeki Araçlar"),
                  Tab(text: "Son Çıkışlar"),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- TAB CONTENT ---
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 1. PARK HALİNDEKİLER
                  FutureBuilder<List<CurrentlyParkedVehicleModel>>(
                    future: _parkedFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Veri alınamadı', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(snapshot.error.toString(), style: TextStyle(color: Colors.grey.shade600, fontSize: 12), textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _loadParked, child: const Text('Tekrar Dene')),
                          ],
                        );
                      }
                      final data = snapshot.data ?? [];
                      final vehicles = data.map((e) {
                        return {
                          'id': '${e.plateNumber}-${e.checkInTime.toIso8601String()}',
                          'plate': e.plateNumber,
                          'vehicleType': e.vehicleType,
                          'ownerName': e.ownerName,
                          'entryTime': _formatDateTime(e.checkInTime),
                          'spotNumber': e.spotCode,
                          'parkingLotName': e.parkingLot,
                          'status': 'parked',
                        };
                      }).toList();
                      return _VehicleGrid(
                        vehicles: vehicles,
                        isParked: true,
                        onAction: (v) => _showExitDialog(v),
                      );
                    },
                  ),
                  // 2. SON ÇIKIŞLAR
                  FutureBuilder<List<ExitPanelCard>>(
                    future: _recentExitsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Veri alınamadı', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(snapshot.error.toString(), style: TextStyle(color: Colors.grey.shade600, fontSize: 12), textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _loadRecentExits, child: const Text('Tekrar Dene')),
                          ],
                        );
                      }
                      final data = snapshot.data ?? [];
                      final vehicles = data.map((e) {
                        final ownerText = e.owner.trim().isEmpty ? '-' : e.owner;
                        final locationText = e.location.trim().isEmpty ? '-' : e.location;
                        return {
                          'id': '${e.plateNumber}-${(e.exitTime ?? DateTime.now()).toIso8601String()}',
                          'plate': e.plateNumber,
                          'vehicleType': e.vehicleType,
                          'ownerName': ownerText,
                          'entryTime': e.entryTime != null ? _formatDateTime(e.entryTime!) : '-',
                          'parkingLotName': locationText,
                          'status': e.status.isNotEmpty ? e.status : 'Çıkış Yapıldı',
                        };
                      }).toList();
                      return _VehicleGrid(
                        vehicles: vehicles,
                        isParked: false,
                        onAction: (v) {},
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- ARAÇ GRID VE KART ---
class _VehicleGrid extends StatelessWidget {
  final List<Map<String, dynamic>> vehicles;
  final bool isParked;
  final Function(Map<String, dynamic>) onAction;

  const _VehicleGrid({required this.vehicles, required this.isParked, required this.onAction});

  @override
  Widget build(BuildContext context) {
    if (vehicles.isEmpty) {
      return const Center(child: Text("Kayıt bulunamadı", style: TextStyle(color: Colors.grey)));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
        return GridView.builder(
          itemCount: vehicles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.6,
          ),
          itemBuilder: (context, index) {
            final vehicle = vehicles[index];
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
                          Text(vehicle['plate'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(vehicle['vehicleType'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: isParked ? Colors.orange.shade50 : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12)
                        ),
                        child: Text(
                            isParked ? vehicle['spotNumber'] : (vehicle['status'] ?? 'Çıkış Yapıldı'),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isParked ? Colors.orange.shade700 : Colors.green.shade700
                            )
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  _InfoRow(label: "Sahibi", value: vehicle['ownerName']),
                  _InfoRow(label: "Giriş", value: vehicle['entryTime']),
                  _InfoRow(label: "Konum", value: vehicle['parkingLotName']),

                  if (isParked) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => onAction(vehicle),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        icon: const Icon(Icons.logout),
                        label: const Text("Çıkış Yap"),
                      ),
                    )
                  ]
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.isBold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? Colors.black87
          )),
        ],
      ),
    );
  }
}
