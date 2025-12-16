import 'package:flutter/material.dart';
import 'dart:math';
import 'models/airport.dart';
import 'services/airports_api.dart';

class AirportsScreen extends StatefulWidget {
  const AirportsScreen({super.key});

  @override
  State<AirportsScreen> createState() => _AirportsScreenState();
}

class _AirportsScreenState extends State<AirportsScreen> {
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  Future<List<Airport>>? _future;
  List<Airport> _items = [];

  // Form Kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _iataController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = AirportsApi.fetchAirports();
  }

  // --- CRUD İŞLEMLERİ ---

  void _showAirportDialog({Airport? airport}) {
    bool _saving = false;
    if (airport != null) {
      _nameController.text = airport.name;
      _cityController.text = airport.city;
      _countryController.text = airport.country;
      _iataController.text = airport.iataCode;
    } else {
      _nameController.clear();
      _cityController.clear();
      _countryController.clear();
      _iataController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final canSubmit = !_saving &&
              _nameController.text.trim().isNotEmpty &&
              _cityController.text.trim().isNotEmpty &&
              _countryController.text.trim().isNotEmpty &&
              _iataController.text.trim().length == 3;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(airport != null ? 'Havalimanı Düzenle' : 'Yeni Havalimanı'),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "Havalimanı Adı",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flight_takeoff),
                        ),
                        validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(
                                labelText: "Şehir",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_city),
                              ),
                              validator: (v) => v!.isEmpty ? "Gerekli" : null,
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _countryController,
                              decoration: const InputDecoration(
                                labelText: "Ülke",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.public),
                              ),
                              validator: (v) => v!.isEmpty ? "Gerekli" : null,
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _iataController,
                        decoration: const InputDecoration(
                          labelText: "IATA Kodu (Örn: IST)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.tag),
                          counterText: "",
                        ),
                        maxLength: 3,
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Zorunlu alan";
                          if (value.length != 3) return "3 karakter olmalı";
                          return null;
                        },
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("İptal", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                onPressed: canSubmit
                    ? () async {
                        if (!_formKey.currentState!.validate()) return;
                        setDialogState(() => _saving = true);
                        try {
                          if (airport != null) {
                            final updated = await AirportsApi.updateAirport(
                              airportId: airport.airportId,
                              name: _nameController.text.trim(),
                              city: _cityController.text.trim(),
                              country: _countryController.text.trim(),
                              iataCode: _iataController.text.trim().toUpperCase(),
                            );
                            final idx = _items.indexWhere((a) => a.airportId == updated.airportId);
                            if (idx >= 0) {
                              setState(() {
                                _items[idx] = updated;
                              });
                            }
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Havalimanı güncellendi.')));
                          } else {
                            final created = await AirportsApi.addAirport(
                              name: _nameController.text.trim(),
                              city: _cityController.text.trim(),
                              country: _countryController.text.trim(),
                              iataCode: _iataController.text.trim().toUpperCase(),
                            );
                            setState(() {
                              _items.insert(0, created);
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Havalimanı eklendi.')));
                          }
                        } catch (e) {
                          setDialogState(() => _saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Güncelleme başarısız: $e')));
                        }
                      }
                    : null,
                child: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Güncelle"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteAirport(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Havalimanını Kapat"),
        content: const Text("Bu işlem havalimanını 'Closed' yapar ve bu havalimanına bağlı tüm uçuşları 'Canceled' yapar. Emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AirportsApi.deleteAirport(id);
                setState(() {
                  _items.removeWhere((a) => a.airportId == id);
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Havalimanı kapatıldı.')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kapatma başarısız: $e')));
              }
            },
            child: const Text("Kapat", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: FutureBuilder<List<Airport>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Havalimanı verisi alınamadı', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), style: TextStyle(color: Colors.grey.shade600, fontSize: 12), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: () => setState(() => _future = AirportsApi.fetchAirports()), child: const Text('Tekrar Dene')),
                ],
              ),
            );
          }
          final data = snapshot.data ?? [];
          if (_items.isEmpty && data.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _items = data);
            });
          }
          final totalPages = (_items.length / _itemsPerPage).ceil();
          if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
          final startIndex = _currentPage * _itemsPerPage;
          final endIndex = min(startIndex + _itemsPerPage, _items.length);
          final currentData = _items.isEmpty ? <Airport>[] : _items.sublist(startIndex, endIndex);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Havalimanı Yönetimi", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                        SizedBox(height: 4),
                        Text("Havalimanlarını yönetin", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAirportDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text("Yeni Havalimanı"),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if ((currentData.isEmpty))
                  const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Havalimanı bulunamadı")))
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
                          childAspectRatio: 2.0,
                        ),
                        itemCount: currentData.length,
                        itemBuilder: (context, index) {
                          final item = currentData[index];
                          return _AirportCard(
                            airport: item,
                            actionsEnabled: true,
                            onEdit: () => _showAirportDialog(airport: item),
                            onDelete: () => _deleteAirport(item.airportId),
                          );
                        },
                      );
                    },
                  ),
                const SizedBox(height: 24),
                if (totalPages > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text("Sayfa ${_currentPage + 1} / $totalPages"),
                      ),
                      IconButton(
                        onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- HAVALİMANI KARTI ---
class _AirportCard extends StatelessWidget {
  final Airport airport;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool actionsEnabled;

  const _AirportCard({required this.airport, required this.onEdit, required this.onDelete, required this.actionsEnabled});

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
          // Üst Kısım: İsim ve IATA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  airport.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  airport.iataCode,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                ),
              ),
            ],
          ),

          const Divider(height: 16),

          // Orta Kısım: Lokasyon
          _InfoRow(icon: Icons.location_city, text: "${airport.city}, ${airport.country}"),

          const SizedBox(height: 8),

          // Alt Kısım: Butonlar
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: actionsEnabled ? onEdit : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 16, color: Colors.teal.shade700),
                          const SizedBox(width: 4),
                          Text("Düzenle", style: TextStyle(color: Colors.teal.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: actionsEnabled ? onDelete : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: Colors.red.shade700),
                          const SizedBox(width: 4),
                          Text("Sil", style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
          child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade700), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
