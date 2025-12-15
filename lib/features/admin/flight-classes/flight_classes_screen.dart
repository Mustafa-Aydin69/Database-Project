import 'package:flutter/material.dart';
import 'dart:math';
import 'models/flight_class.dart';
import 'services/flight_class_service.dart';

class FlightClassesScreen extends StatefulWidget {
  const FlightClassesScreen({super.key});

  @override
  State<FlightClassesScreen> createState() => _FlightClassesScreenState();
}

class _FlightClassesScreenState extends State<FlightClassesScreen> {
  Future<List<FlightClass>>? _future;
  List<FlightClass> _items = [];

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = FlightClassService.getFlightClasses();
  }

  void _showClassDialog({FlightClass? flightClass}) {
    bool saving = false;
    if (flightClass != null) {
      _classNameController.text = flightClass.className;
      _descriptionController.text = flightClass.description;
    } else {
      _classNameController.clear();
      _descriptionController.clear();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final canSubmit = !saving && _classNameController.text.trim().isNotEmpty;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(flightClass != null ? 'Sınıf Düzenle' : 'Yeni Sınıf'),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _classNameController,
                        decoration: const InputDecoration(
                          labelText: "Sınıf Adı",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.class_outlined),
                        ),
                        validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: "Açıklama",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        maxLines: 3,
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
                        setDialogState(() => saving = true);
                        try {
                          if (flightClass != null) {
                            final updated = await FlightClassService.updateFlightClass(
                              classId: flightClass.classId,
                              className: _classNameController.text.trim(),
                              description: _descriptionController.text.trim(),
                            );
                            final idx = _items.indexWhere((c) => c.classId == updated.classId);
                            if (idx >= 0) {
                              setState(() {
                                _items[idx] = updated;
                              });
                            }
                          } else {
                            final created = await FlightClassService.createFlightClass(
                              className: _classNameController.text.trim(),
                              description: _descriptionController.text.trim(),
                            );
                            setState(() {
                              _items.insert(0, created);
                            });
                          }
                          Navigator.pop(context);
                        } catch (e) {
                          setDialogState(() => saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                          );
                        } finally {
                          setDialogState(() => saving = false);
                        }
                      }
                    : null,
                child: saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Kaydet"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteClass(FlightClass fc) {
    if (fc.classId == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Varsayılan sınıf (ID: 1) silinemez.')),
      );
      return;
    }
    bool deleting = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Uçuş sınıfı silinsin mi?"),
            content: Text("${fc.className} (ID: ${fc.classId}) silinsin mi?"),
            actions: [
              TextButton(onPressed: deleting ? null : () => Navigator.pop(context), child: const Text("İptal")),
              TextButton(
                onPressed: deleting
                    ? null
                    : () async {
                        setDialogState(() => deleting = true);
                        try {
                          final result = await FlightClassService.deleteFlightClass(fc.classId);
                          setState(() {
                            _items.removeWhere((c) => c.classId == fc.classId);
                          });
                          Navigator.pop(context);
                          final seats = (result['seatsReassigned'] as num?)?.toInt() ?? 0;
                          final prices = (result['flightPricingReassigned'] as num?)?.toInt() ?? 0;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Sınıf silindi. $seats koltuk ve $prices fiyat varsayılan sınıfa aktarıldı.")),
                          );
                        } catch (e) {
                          setDialogState(() => deleting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                          );
                        }
                      },
                child: deleting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Sil", style: TextStyle(color: Colors.red)),
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
      body: FutureBuilder<List<FlightClass>>(
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
                  Text('Uçuş sınıfları alınamadı', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), style: TextStyle(color: Colors.grey.shade600, fontSize: 12), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: () => setState(() => _future = FlightClassService.getFlightClasses()), child: const Text('Tekrar Dene')),
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
          return Padding(
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
                        Text("Uçuş Sınıfları", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                        SizedBox(height: 4),
                        Text("Uçuş sınıflarını yönetin", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showClassDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text("Yeni Sınıf"),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _items.isEmpty
                      ? const Center(child: Text("Kayıt bulunamadı."))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
                            return GridView.builder(
                              padding: EdgeInsets.zero,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 2.0,
                              ),
                              itemCount: _items.length,
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                return _FlightClassCard(
                                  key: ValueKey(item.classId),
                                  flightClass: item,
                                  onEdit: () => _showClassDialog(flightClass: item),
                                  onDelete: () => _deleteClass(item),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- SINIF KARTI ---
class _FlightClassCard extends StatelessWidget {
  final FlightClass flightClass;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FlightClassCard({super.key, required this.flightClass, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
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
                Text(
                  flightClass.className,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Text("ID: ${flightClass.classId}", style: TextStyle(fontSize: 11, color: Colors.teal.shade700)),
                ),
              ],
            ),
            const Divider(height: 16),
            Expanded(
              child: Text(
                flightClass.description.isEmpty ? "Açıklama yok" : flightClass.description,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onEdit,
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
                    onTap: onDelete,
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
      ),
    );
  }
}
