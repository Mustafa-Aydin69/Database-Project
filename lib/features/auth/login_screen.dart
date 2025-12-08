import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form verilerini tutmak için Controller'lar (React'teki useState gibi)
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // State değişkenleri
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Giriş Mantığı (React'teki handleLogin fonksiyonu)
  Future<void> _handleLogin() async {
    // Klavye açıksa kapatalım
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // API gecikmesi simülasyonu (setTimeout)
    await Future.delayed(const Duration(seconds: 1));

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!mounted) return; // Ekran kapandıysa işlem yapma

    // 1. Admin Girişi
    if (email == 'admin@gmail.com' && password == 'admin') {
      // LocalStorage işlemleri buraya (SharedPrefs) eklenebilir
      context.go('/admin/dashboard');
    }
    // 2. Kontuar (Check-in) Girişi
    else if (email == 'mustafa@gmail.com' && password == '1234') {
      context.go('/checkin/dashboard');
    }
    // 3. Otopark Girişi
    else if (email == 'park@gmail.com' && password == '1234') {
      context.go('/parking/dashboard');
    }
    // Hatalı Giriş
    else {
      setState(() {
        _errorMessage = 'Email veya şifre hatalı';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // React: bg-gradient-to-br from-teal-50 via-white to-orange-50
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0FDFA), // teal-50
              Colors.white,
              Color(0xFFFFF7ED), // orange-50
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              // React: max-w-md (Maksimum genişlik sınırlaması)
              constraints: const BoxConstraints(maxWidth: 450),
              child: Card(
                elevation: 10, // React: shadow-xl
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // React: rounded-2xl
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(32.0), // React: p-8
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- HEADER KISMI ---
                      Center(
                        child: Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.teal, Color(0xFF0D9488)], // teal-500 to teal-600
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.flight, color: Colors.white, size: 32),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "AirportServices",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Giriş Paneli",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 32),

                      // --- HATA MESAJI (Varsa göster) ---
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2), // red-50
                            border: Border.all(color: const Color(0xFFFECACA)), // red-200
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                            ],
                          ),
                        ),

                      // --- EMAIL INPUT ---
                      const Text("Email Adresi", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: "ornek@airportservices.com",
                          prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- PASSWORD INPUT ---
                      const Text("Şifre", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "••••••••",
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // --- REMEMBER ME & FORGOT PASSWORD ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 24, width: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: Colors.teal,
                                  onChanged: (val) {
                                    setState(() => _rememberMe = val ?? false);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text("Beni hatırla", style: TextStyle(fontSize: 13)),
                            ],
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text("Şifreyi unuttum?", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w600)),
                          )
                        ],
                      ),

                      const SizedBox(height: 24),

                      // --- LOGIN BUTTON ---
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 4,
                          shadowColor: Colors.teal.withOpacity(0.3),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                            : const Text("Giriş Yap", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),

                      // --- FOOTER ---
                      const SizedBox(height: 24),
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: Text(
                          "© 2025 AirportServices. Tüm hakları saklıdır.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}