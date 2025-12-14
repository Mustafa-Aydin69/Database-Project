import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart'; // UserRole enum'unun burada tanımlı olduğu varsayılır

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  
  // Kullanıcı doğrulama işlemi
  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!mounted) return;

    try {
      // API üzerinden giriş yap
      final authService = AuthService();
      final response = await authService.authenticate(
        email: email,
        password: password,
      );

      if (response != null && response['success'] == true) {
        // Giriş başarılı - RoleName'e göre role belirleme
        final roleName = response['data']['roleName'] as String? ?? '';
        print('🔍 Flutter Debug - RoleName from API: "$roleName"');
        print('🔍 Flutter Debug - RoleName type: ${roleName.runtimeType}');
        print('🔍 Flutter Debug - RoleName isEmpty: ${roleName.isEmpty}');
        
        // RoleName boşsa hata ver
        if (roleName.isEmpty) {
          setState(() {
            _errorMessage = 'Kullanıcı rolü bulunamadı';
          });
          return;
        }
        
        // RoleName'e göre UserRole belirleme
        UserRole userRole = _mapRoleNameToUserRole(roleName);
        print('🔍 Flutter Debug - Mapped UserRole: $userRole');

        // UserID'yi al
        final userId = response['data']['userId'] as int?;
        print('🔍 Flutter Debug - UserID: $userId');

        // Kullanıcıyı giriş yapmış olarak kaydediyoruz (UserID ile birlikte)
        authService.login(userRole, userId: userId);

        // Yönlendirme işlemi - Her rol için yetkisine göre yönlendir
        switch (userRole) {
          case UserRole.admin:
            // Admin: Her yere erişebilir, admin dashboard'a yönlendir
            context.go('/admin/dashboard');
            break;
          
          case UserRole.airportManager:
            // Airport Manager: Kullanıcı, Uçuş, Rezervasyon, Çalışanlar + Dashboard
            context.go('/admin/dashboard');
            break;
          
          case UserRole.flightManager:
            // Flight Manager: Havayolu, Havalimanı, Gate, Flights, Flight Crew + Dashboard
            context.go('/admin/dashboard');
            break;
          
          case UserRole.parkingManager:
            // Parking Manager: Otopark Yönetimi + Dashboard
            context.go('/admin/dashboard');
            break;
          
          case UserRole.checkInStaff:
            // Check-In Staff: Sadece Check-in Modülü
            context.go('/checkin/dashboard');
            break;
          
          case UserRole.parkingStaff:
            // Parking Staff: Sadece Operasyonel Parking Modülü
            context.go('/parking/dashboard');
            break;
          
          case UserRole.user:
            // Customer: Müşteri paneline yönlendir
            context.go('/customer/dashboard');
            break;
        }
      } else {
        // Giriş başarısız
        setState(() {
          _errorMessage = response?['message'] ?? 'Kullanıcı adı veya şifre yanlış';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Beklenmedik bir hata oluştu: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  

  // RoleName'e göre UserRole enum'una dönüştürme fonksiyonu
  UserRole _mapRoleNameToUserRole(String roleName) {
    // RoleName'i normalize et (trim ve küçük harfe çevir)
    final normalizedRoleName = roleName.trim();
    
    print('🔍 Mapping RoleName: "$roleName" -> normalized: "$normalizedRoleName"');
    
    // RoleName'e göre role belirleme
    switch (normalizedRoleName) {
      case 'Admin':
        print('✅ Matched: Admin');
        return UserRole.admin;
      
      case 'AirportManager':
        print('✅ Matched: AirportManager');
        return UserRole.airportManager;
      
      case 'FlightManager':
        print('✅ Matched: FlightManager');
        return UserRole.flightManager;
      
      case 'CheckInStaff':
        print('✅ Matched: CheckInStaff');
        return UserRole.checkInStaff;
      
      case 'ParkingManager':
        print('✅ Matched: ParkingManager');
        return UserRole.parkingManager;
      
      case 'ParkingStaff':
        print('✅ Matched: ParkingStaff');
        return UserRole.parkingStaff;
      
      case 'Customer':
        print('✅ Matched: Customer (mapped to user)');
        return UserRole.user; // Customer için user rolü kullanılıyor
      
      default:
        print('❌ Unknown RoleName: "$roleName"');
        return UserRole.user;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              constraints: const BoxConstraints(maxWidth: 450),
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.teal, Color(0xFF0D9488)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.flight,
                            color: Colors.white,
                            size: 32,
                          ),
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

                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            border: Border.all(color: const Color(0xFFFECACA)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const Text(
                        "Email Adresi",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: "ornek@airportservices.com",
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        "Şifre",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "••••••••",
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 4,
                          shadowColor: Colors.teal.withOpacity(0.3),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Giriş Yap",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),

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
