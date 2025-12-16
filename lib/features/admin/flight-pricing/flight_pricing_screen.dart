import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../../core/services/flight_pricing_service.dart';

class FlightPricingScreen extends StatefulWidget {
  const FlightPricingScreen({super.key});

  @override
  State<FlightPricingScreen> createState() => _FlightPricingScreenState();
}

class _FlightPricingScreenState extends State<FlightPricingScreen> {
  // --- STATE ---
  int _currentPage = 0;
  final int _itemsPerPage = 15; // User requested 15
  String _searchTerm = "";
  String _filterClass = "";

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  int? _selectedFlightID;
  int? _selectedClassID;
  final TextEditingController _priceController = TextEditingController();

  // Dynamic Lists
  List<Map<String, dynamic>> _availableFlights = [];
  List<Map<String, dynamic>> _availableClasses = [];

  // Data
  List<FlightPriceItem> _prices = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    
    final results = await Future.wait([
      FlightPricingService().fetchPrices(),
      FlightPricingService().fetchFlights(),
      FlightPricingService().fetchClasses(),
    ]);

    setState(() {
      _prices = results[0] as List<FlightPriceItem>;
      _availableFlights = results[1] as List<Map<String, dynamic>>;
      _availableClasses = results[2] as List<Map<String, dynamic>>;
      _loading = false;
    });
  }

  // --- FILTERING ---
  List<FlightPriceItem> get _filteredPrices {
    return _prices.where((p) {
      final matchesSearch = p.flightLabel.toLowerCase().contains(_searchTerm.toLowerCase());
      // Filter by class name if needed, but for now we filter by flight label search
      // Assuming _filterClass is for dropdown filter which is not fully implemented in UI yet or redundant
      return matchesSearch; 
    }).toList();
  }

  // --- CRUD ---
  void _showPriceDialog({FlightPriceItem? item}) {
    if (item != null) {
      _selectedFlightID = item.flightID;
      _selectedClassID = item.classID;
      _priceController.text = item.price.toString();
    } else {
      _selectedFlightID = null;
      _selectedClassID = null;
      _priceController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        final bool isEditing = item != null;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEditing ? 'Fiyat Düzenle' : 'Yeni Fiyat'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // FLIGHT DROPDOWN
                    DropdownButtonFormField<int>(
                      value: _selectedFlightID,
                      decoration: const InputDecoration(
                        labelText: "Uçuş",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flight),
                      ),
                      items: _availableFlights.map((f) => DropdownMenuItem(
                        value: f['FlightID'] as int,
                        child: Text(f['Label'] ?? '', overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: isEditing ? null : (val) => setState(() => _selectedFlightID = val),
                      validator: (v) => v == null ? "Seçiniz" : null,
                      isExpanded: true,
                    ),
                    const SizedBox(height: 16),

                    // CLASS DROPDOWN
                    DropdownButtonFormField<int>(
                      value: _selectedClassID,
                      decoration: const InputDecoration(
                        labelText: "Sınıf",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.class_),
                      ),
                      items: _availableClasses.map((c) => DropdownMenuItem(
                        value: c['ClassID'] as int,
                        child: Text(c['ClassName'] ?? ''),
                      )).toList(),
                      onChanged: isEditing ? null : (val) => setState(() => _selectedClassID = val),
                      validator: (v) => v == null ? "Seçiniz" : null,
                    ),
                    const SizedBox(height: 16),

                    // PRICE INPUT
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: "Fiyat (₺)",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Zorunlu alan";
                        if (double.tryParse(v) == null) return "Geçerli bir sayı giriniz";
                        return null;
                      },
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final price = double.parse(_priceController.text);
                  bool success;
                  
                  if (isEditing) {
                    success = await FlightPricingService().updatePrice(
                      item!.pricingID, 
                      _selectedFlightID!, 
                      _selectedClassID!, 
                      price
                    );
                  } else {
                    success = await FlightPricingService().addPrice(
                      _selectedFlightID!, 
                      _selectedClassID!, 
                      price
                    );
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İşlem başarılı")));
                      _fetchData();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hata oluştu")));
                    }
                  }
                }
              },
              child: Text(isEditing ? "Güncelle" : "Ekle"),
            ),
          ],
        );
      },
    );
  }

  void _deletePrice(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Bu fiyatı silmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await FlightPricingService().deletePrice(id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Silindi")));
                _fetchData();
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
    final filtered = _filteredPrices;
    final totalPages = (filtered.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    if (totalPages == 0) _currentPage = 0;
    
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = min(startIndex + _itemsPerPage, filtered.length);
    final currentData = filtered.isEmpty ? <FlightPriceItem>[] : filtered.sublist(startIndex, endIndex);

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
                    Text("Uçuş Fiyatlandırma", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text("Uçuş sınıflarına göre fiyat yönetimi", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showPriceDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Yeni Fiyat"),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- FILTERS ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: TextField(
                onChanged: (val) => setState(() => _searchTerm = val),
                decoration: const InputDecoration(
                  hintText: "Uçuş ara...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (currentData.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Fiyat bulunamadı.")))
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
                      childAspectRatio: 2.2,
                    ),
                    itemCount: currentData.length,
                    itemBuilder: (context, index) {
                      return _PriceCard(
                        item: currentData[index],
                        onEdit: () => _showPriceDialog(item: currentData[index]),
                        onDelete: () => _deletePrice(currentData[index].pricingID),
                      );
                    },
                  );
                },
              ),

            // --- PAGINATION ---
            const SizedBox(height: 24),
            if (totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Previous
                  InkWell(
                    onTap: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: _currentPage > 0 ? Colors.white : Colors.grey.shade100,
                      ),
                      child: Icon(Icons.chevron_left, color: _currentPage > 0 ? Colors.black87 : Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Numbered Pages
                  ...List.generate(totalPages, (index) {
                    if (totalPages > 10 && (index > 2 && index < totalPages - 3 && (index < _currentPage - 1 || index > _currentPage + 1))) {
                      if (index == 3 && _currentPage > 4) return const Text(" ... ");
                      if (index == totalPages - 4 && _currentPage < totalPages - 5) return const SizedBox();
                      return const SizedBox.shrink();
                    }
                    final isSelected = _currentPage == index;
                    return GestureDetector(
                      onTap: () => setState(() => _currentPage = index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.teal : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? Colors.teal : Colors.grey.shade300),
                          boxShadow: isSelected ? [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : null,
                        ),
                        child: Text("${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
                      ),
                    );
                  }).where((w) => w is! SizedBox),

                  const SizedBox(width: 12),
                  
                  // Next
                  InkWell(
                    onTap: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: _currentPage < totalPages - 1 ? Colors.white : Colors.grey.shade100,
                      ),
                      child: Icon(Icons.chevron_right, color: _currentPage < totalPages - 1 ? Colors.black87 : Colors.grey),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final FlightPriceItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PriceCard({required this.item, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
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
                  item.flightLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  item.className,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Center(
            child: Text(
              currencyFormat.format(item.price),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
          ),
          const Divider(height: 20),
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

