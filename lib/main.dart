import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // 1. BU SATIRI EKLE
import 'router/app_router.dart';

void main() async { // 2. BURAYI 'async' YAP
  // 3. BU SATIRI EKLE (Türkçe tarih verisini yükler)
  await initializeDateFormatting('tr_TR', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Airport Services',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      ),
      routerConfig: appRouter,
    );
  }
}