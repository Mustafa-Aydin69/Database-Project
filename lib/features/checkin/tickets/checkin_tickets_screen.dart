import 'package:flutter/material.dart';
import '../../../core/services/checkin_service.dart';

class CheckInTicketsScreen extends StatefulWidget {
  const CheckInTicketsScreen({super.key});

  @override
  State<CheckInTicketsScreen> createState() => _CheckInTicketsScreenState();
}

class _CheckInTicketsScreenState extends State<CheckInTicketsScreen> {
  // --- STATE ---
  final CheckInService _checkInService = CheckInService();
  bool _isLoading = true;
  List<CheckInTicket> _tickets = [];
  String _searchTerm = "";
  String _filterStatus = "all"; // 'all', 'Bekleyen', 'Tamamlanan'

  // Modal Kontrolcüleri
  final TextEditingController _passportController = TextEditingController();
  String? _passportError;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  /// API'den bilet listesini yükle
  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
    });

    final tickets = await _checkInService.getTicketList();

    setState(() {
      _tickets = tickets;
      _isLoading = false;
    });
  }

  // --- MOCK VERİLER (KALDIRILDI) ---
  // Artık API'den gelen veriler kullanılıyor

  // --- FİLTRELEME ---
  List<CheckInTicket> get _filteredTickets {
    return _tickets.where((ticket) {
      final matchesSearch =
          ticket.passengerName.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          ticket.passportNo.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          ticket.route.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          ticket.reservationNo.toLowerCase().contains(_searchTerm.toLowerCase());

      final matchesFilter =
          _filterStatus == 'all' || ticket.status == _filterStatus;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  // --- CHECK-IN İŞLEMİ ---
  void _showCheckInDialog(CheckInTicket ticket) {
    _passportController.clear();
    _passportError = null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Pasaport Numarası Girin"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _passportController,
                  decoration: const InputDecoration(
                    labelText: "Pasaport No",
                    hintText: "Örn: U12345678",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    setModalState(() {
                      _passportController.text = val.toUpperCase();
                      _passportController
                          .selection = TextSelection.fromPosition(
                        TextPosition(offset: _passportController.text.length),
                      );
                      _passportError = null;
                    });
                  },
                ),
                if (_passportError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _passportError!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "İptal",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (_passportController.text.trim().isEmpty) {
                    setModalState(
                      () => _passportError =
                          "Pasaport numarası girilmesi zorunludur",
                    );
                    return;
                  }

                  // Check-in Tamamla (Backend'e istek gönderilecek - şimdilik sadece UI güncellemesi)
                  // TODO: Backend API endpoint'i eklendiğinde burada API çağrısı yapılacak
                  setState(() {
                    final index = _tickets.indexWhere(
                      (t) => t.reservationNo == ticket.reservationNo,
                    );
                    if (index != -1) {
                      // Yeni ticket oluştur (immutable olduğu için)
                      _tickets[index] = CheckInTicket(
                        reservationNo: ticket.reservationNo,
                        passengerName: ticket.passengerName,
                        passportNo: _passportController.text.trim(),
                        route: ticket.route,
                        reservationDate: ticket.reservationDate,
                        seatInfo: ticket.seatInfo,
                        status: 'Tamamlanan',
                      );
                    }
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Check-in başarıyla tamamlandı."),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Verileri yeniden yükle
                  _loadTickets();
                },
                child: const Text("Onayla"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTickets;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bilet Check-in",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Yolcu biletlerini kontrol edin ve check-in yapın",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- FİLTRELER VE ARAMA ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => setState(() => _searchTerm = val),
                    decoration: const InputDecoration(
                      hintText:
                          "Rezervasyon no, yolcu adı veya pasaport ara...",
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterButton(
                          label: "Tümü",
                          isActive: _filterStatus == 'all',
                          onTap: () => setState(() => _filterStatus = 'all'),
                        ),
                        const SizedBox(width: 8),
                        _FilterButton(
                          label: "Bekleyen",
                          isActive: _filterStatus == 'Bekleyen',
                          onTap: () =>
                              setState(() => _filterStatus = 'Bekleyen'),
                        ),
                        const SizedBox(width: 8),
                        _FilterButton(
                          label: "Tamamlanan",
                          isActive: _filterStatus == 'Tamamlanan',
                          onTap: () =>
                              setState(() => _filterStatus = 'Tamamlanan'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- KART LİSTESİ ---
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filtered.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text(
                    _tickets.isEmpty
                        ? "Check-in yapılacak bilet bulunmamaktadır."
                        : "Arama kriterlerinize uygun kayıt bulunamadı.",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  // Masaüstünde 3, Tablette 2, Mobilde 1 kolon
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
                      childAspectRatio: 1.5, // Kart boyutu
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _TicketCard(
                        ticket: filtered[index],
                        onCheckIn: () => _showCheckInDialog(filtered[index]),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// --- YARDIMCI WIDGETLAR ---

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.orange : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final CheckInTicket ticket;
  final VoidCallback onCheckIn;

  const _TicketCard({required this.ticket, required this.onCheckIn});

  @override
  Widget build(BuildContext context) {
    bool isCompleted = ticket.isCompleted;
    Color statusColor = isCompleted ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Üst Kısım: Yolcu ve ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.passengerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      ticket.reservationNo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle : Icons.schedule,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ticket.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 16),

          // Orta Kısım: Detaylar
          _InfoRow(icon: Icons.flight_takeoff, text: ticket.route),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.calendar_today,
            text: ticket.reservationDate,
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.event_seat,
            text: ticket.seatInfo,
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.contact_page,
            text: ticket.passportNo,
          ),

          const SizedBox(height: 12),

          // Alt Kısım: Buton
          if (!isCompleted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.check),
                label: const Text("Check-in Yap"),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  "İşlem Tamamlandı",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
