import 'package:flutter/material.dart';
import 'dart:math';

class GatesScreen extends StatefulWidget {
  const GatesScreen({super.key});

  @override
  State<GatesScreen> createState() => _GatesScreenState();
}

class _GatesScreenState extends State<GatesScreen> {
  // --- STATE ---
  int _currentPage = 0;
  final int _itemsPerPage = 12; // Kapı kartları küçük olduğu için 12 adet gösterelim

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _gateNumController = TextEditingController();
  final TextEditingController _terminalController = TextEditingController();
  final TextEditingController _flightController = TextEditingController();
  String _selectedStatus = 'Available';

  // Sabit Listeler
  final List<String> _statuses = ['Available', 'Occupied', 'Maintenance'];

  // --- MOCK VERİLER (React'ten alındı) ---
  List<Map<String, dynamic>> _gates = [
    {'id': 1, 'gateNumber': 'A1', 'terminal': 'Terminal 1', 'status': 'Occupied', 'currentFlight': 'TK1234'},
    {'id': 2, 'gateNumber': 'A2', 'terminal': 'Terminal 1', 'status': 'Available', 'currentFlight': '-'},
    {'id': 3, 'gateNumber': 'B1', 'terminal': 'Terminal 2', 'status': 'Maintenance', 'currentFlight': '-'},
    {'id': 4, 'gateNumber': 'B2', 'terminal': 'Terminal 2', 'status': 'Occupied', 'currentFlight': 'PC5678'},
    {'id': 5, 'gateNumber': 'C1', 'terminal': 'Terminal 3', 'status': 'Available', 'currentFlight': '-'},
    // Sayfalama için veri çoğaltma
    ...List.generate(15, (index) => {
      'id': 6 + index,
      'gateNumber': 'D${index + 1}',
      'terminal': 'Terminal 3',
      'status': index % 3 == 0 ? 'Available' : (index % 3 == 1 ? 'Occupied' : 'Maintenance'),
      'currentFlight': index % 3 == 1 ? 'TK${2000 + index}' : '-'
    }),
  ];

  // --- CRUD İŞLEMLERİ ---

  void _showGateDialog({Map<String, dynamic>? gate}) {
    if (gate != null) {
      _gateNumController.text = gate['gateNumber'];
      _terminalController.text = gate['terminal'];
      _flightController.text = gate['currentFlight'];
      _selectedStatus = gate['status'];
    } else {
      _gateNumController.clear();
      _terminalController.clear();
      _flightController.text = "-";
      _selectedStatus = 'Available';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(gate != null ? 'Kapı Düzenle' : 'Yeni Kapı'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _gateNumController,
                          decoration: const InputDecoration(labelText: "Kapı No", border: OutlineInputBorder()),
                          validator: (v) => v!.isEmpty ? "Zorunlu" : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _terminalController,
                          decoration: const InputDecoration(labelText: "Terminal", border: OutlineInputBorder()),
                          validator: (v) => v!.isEmpty ? "Zorunlu" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(labelText: "Durum", border: OutlineInputBorder()),
                    items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => _selectedStatus = val!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _flightController,
                    decoration: const InputDecoration(labelText: "Mevcut Uçuş (Yoksa '-')", border: OutlineInputBorder()),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  if (gate != null) {
                    final index = _gates.indexWhere((g) => g['id'] == gate['id']);
                    _gates[index] = {
                      'id': gate['id'],
                      'gateNumber': _gateNumController.text,
                      'terminal': _terminalController.text,
                      'status': _selectedStatus,
                      'currentFlight': _flightController.text,
                    };
                  } else {
                    _gates.insert(0, {
                      'id': DateTime.now().millisecondsSinceEpoch,
                      'gateNumber': _gateNumController.text,
                      'terminal': _terminalController.text,
                      'status': _selectedStatus,
                      'currentFlight': _flightController.text,
                    });
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text(gate != null ? "Güncelle" : "Ekle"),
          ),
        ],
      ),
    );
  }

  void _deleteGate(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Bu kapıyı silmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          TextButton(
            onPressed: () {
              setState(() => _gates.removeWhere((g) => g['id'] == id));
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Kapı Yönetimi", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text("Havalimanı kapılarını yönetin", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showGateDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Yeni Kapı"),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- KART LİSTESİ ---
            if (currentData.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Kapı bulunamadı.")))
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  // Kapı kartları küçük, bu yüzden daha fazla sütun kullanabiliriz
                  int crossAxisCount = constraints.maxWidth > 1100 ? 4 : (constraints.maxWidth > 700 ? 2 : 1);
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
                        gate: currentData[index],
                        onEdit: () => _showGateDialog(gate: currentData[index]),
                        onDelete: () => _deleteGate(currentData[index]['id']),
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
  final Map<String, dynamic> gate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GateCard({required this.gate, required this.onEdit, required this.onDelete});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available': return Colors.green;
      case 'Occupied': return Colors.red;
      case 'Maintenance': return Colors.amber;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(gate['status']);

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
              Text("Kapı ${gate['gateNumber']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(gate['status'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),

          const Divider(height: 16),

          Row(
            children: [
              const Icon(Icons.business, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(gate['terminal'], style: const TextStyle(fontSize: 13, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.flight, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text("Uçuş: ${gate['currentFlight']}", style: const TextStyle(fontSize: 13, color: Colors.black87)),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(onTap: onEdit, child: const Icon(Icons.edit, size: 18, color: Colors.teal)),
              const SizedBox(width: 12),
              InkWell(onTap: onDelete, child: const Icon(Icons.delete_outline, size: 18, color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }
}