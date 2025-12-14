import 'package:flutter/material.dart';
import 'dart:math';
import '../../../core/services/admin_service.dart';

class GatesScreen extends StatefulWidget {
  const GatesScreen({super.key});

  @override
  State<GatesScreen> createState() => _GatesScreenState();
}

class _GatesScreenState extends State<GatesScreen> {
  // --- STATE ---
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<Gate> _gates = [];
  int _currentPage = 0;
  final int _itemsPerPage = 12; // Kapı kartları küçük olduğu için 12 adet gösterelim


  @override
  void initState() {
    super.initState();
    _loadGates();
  }

  /// API'den kapı listesini yükle
  Future<void> _loadGates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final gates = await _adminService.getGates();
      debugPrint('📥 Gates loaded: ${gates.length} items');
      
      setState(() {
        _gates = gates;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading gates: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final totalPages = (_gates.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = min(startIndex + _itemsPerPage, _gates.length);
    final currentData = _gates.isEmpty ? [] : _gates.sublist(startIndex, endIndex);

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
                Text("Kapı Yönetimi", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                SizedBox(height: 4),
                Text("Havalimanı kapılarını yönetin", style: TextStyle(color: Colors.grey)),
              ],
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
                            child: Text("Kapı bulunamadı.")))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          // Kapı kartları küçük, bu yüzden daha fazla sütun kullanabiliriz
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
                              childAspectRatio: 1.8,
                            ),
                            itemCount: currentData.length,
                            itemBuilder: (context, index) {
                              return _GateCard(
                                key: ValueKey(currentData[index].gateId ?? index),
                                gate: currentData[index],
                                onEdit: null,
                                onDelete: null,
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

// --- KAPI KARTI ---
class _GateCard extends StatelessWidget {
  final Gate gate;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _GateCard({Key? key, required this.gate, this.onEdit, this.onDelete}) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'Occupied':
        return Colors.red;
      case 'Maintenance':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(gate.status ?? 'Available');
    final displayGateNumber = gate.gateNumber ?? 'Atanmamış';

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
              Text("Kapı $displayGateNumber",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(gate.status ?? 'N/A',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor)),
              ),
            ],
          ),

          const Divider(height: 16),

          Row(
            children: [
              const Icon(Icons.tag, size: 16, color: Colors.purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text("GateID: ${gate.gateId ?? 'N/A'}",
                    style: const TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          if (gate.terminal != null && gate.terminal!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.business, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(gate.terminal!,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
          if (gate.currentFlight != null && gate.currentFlight!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.flight, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text("Uçuş: ${gate.currentFlight}",
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
          if (gate.airportName != null && gate.airportName!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.airport_shuttle, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(gate.airportName!,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
          if (gate.airlineName != null && gate.airlineName!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.airlines, size: 16, color: Colors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(gate.airlineName!,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [],
          ),
        ],
      ),
    );
  }
}