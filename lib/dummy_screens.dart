import 'package:flutter/material.dart';

// Bu dosya artık kullanılmamaktadır.
// Tüm ekranlar gerçek 'features' klasörlerine taşınmıştır.
// Proje derlenirken hata almamak için boş bir widget bırakılmıştır.

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text("Bu ekran artık kullanılmıyor.")),
    );
  }
}