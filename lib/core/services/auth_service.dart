// auth_service.dart - Son ve Eksiksiz Versiyon

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Rollerimizi Enum olarak tanımlayalım
enum UserRole {
  admin,
  airportManager,
  flightManager,
  parkingManager,
  checkInStaff,
  parkingStaff,
  user // Genel/tanımsız kullanıcı
}

class AuthService {
  // Singleton yapısı (Her yerden aynı veriye ulaşmak için)
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // ⚠️ API Adresi: Chrome/Web uygulaması için localhost kullanılmalıdır.
  static const String _loginApiUrl = 'http://localhost:3000/api/login'; 
  static const String _logoutApiUrl = 'http://localhost:3000/api/logout';
  // Mobil (Android Emülatörü) için: 'http://10.0.2.2:3000/api/login'
  // Mobil (Gerçek Cihaz) için: Bilgisayarınızın yerel IP adresi.

  // Şu anki kullanıcı rolü (Varsayılan olarak null - giriş yapılmamış)
  UserRole? _currentRole;
  
  // Şu anki kullanıcı ID'si (Logout için gerekli)
  int? _currentUserId;

  // ------------------------------------------------------------------
  // 1. API İLE İLETİŞİM METODU
  // ------------------------------------------------------------------

  /// API ÜZERİNDEN KULLANICIYI DOĞRULAMA (MS SQL Kontrolü)
  /// Başarılıysa kullanıcı verilerini içeren harita, başarısızsa hata mesajı veya null döner.
  Future<Map<String, dynamic>?> authenticate({
    required String email, 
    required String password
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_loginApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        // Giriş başarılı (API'den success: true yanıtı alındı)
        return responseBody;
      } else {
        // Hata kodu (401 Unauthorized, 400 Bad Request vb.)
        final errorMessage = responseBody['message'] ?? 'Sunucu hatası. Kod: ${response.statusCode}';
        // Giriş başarısız olduğunda da mesajı döndürelim
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      // Ağ bağlantısı hatası (API sunucusuna erişilemedi veya 500 hatası)
      debugPrint('HTTP Login Hatası: $e');
      // Null döndürerek LoginScreen'de sunucu hatası gösterilmesini sağla
      return null; 
    }
  }

  // ------------------------------------------------------------------
  // 2. OTURUM YÖNETİMİ
  // ------------------------------------------------------------------

  // Giriş Yapma (Rolü ve UserID'yi kaydeder)
  void login(UserRole role, {int? userId}) {
    _currentRole = role;
    _currentUserId = userId;
    debugPrint("Kullanıcı giriş yaptı. Rol: $role, UserID: $userId");
    // Gerçek uygulamada burada SharedPreferences veya secure storage kullanılır.
  }

  // Çıkış Yapma (Stored procedure ile loglanır)
  Future<void> logout() async {
    final userId = _currentUserId;
    
    // UserID varsa backend'e logout isteği gönder
    if (userId != null) {
      try {
        final response = await http.post(
          Uri.parse(_logoutApiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'userId': userId}),
        );

        if (response.statusCode == 200) {
          debugPrint("✅ Logout başarılı ve loglandı. UserID: $userId");
        } else {
          debugPrint("⚠️ Logout loglama hatası: ${response.statusCode}");
        }
      } catch (e) {
        debugPrint("❌ Logout API hatası: $e");
        // Hata olsa bile logout işlemini tamamla
      }
    }

    // Oturum bilgilerini temizle
    _currentRole = null;
    _currentUserId = null;
    debugPrint("Kullanıcı çıkış yaptı.");
  }

  // Şu anki rolü getir
  UserRole? get currentRole => _currentRole;
  int? get currentUserId => _currentUserId;

  // ------------------------------------------------------------------
  // 3. YETKİ KONTROLÜ (ROUTER GUARD)
  // ------------------------------------------------------------------

  /// Verilen 'path' (örneğin '/admin/users') için şu anki rolün yetkisi var mı?
  bool hasAccess(String path) {
    if (_currentRole == null) return false;

    // 1. ADMIN (Her yere girebilir)
    if (_currentRole == UserRole.admin) return true;

    // 2. CHECK-IN PERSONELİ (Sadece Check-in Modülü)
    if (_currentRole == UserRole.checkInStaff) {
      return path.startsWith('/checkin');
    }

    // 3. OTOPARK SAHA PERSONELİ (Sadece Operasyonel Parking Modülü)
    if (_currentRole == UserRole.parkingStaff) {
      return path.startsWith('/parking');
    }

    // --- ADMIN PANELİ YÖNETİCİLERİ ---

    // 4. PARKING MANAGER (Sadece Otopark Yönetimi + Dashboard)
    if (_currentRole == UserRole.parkingManager) {
      return path.startsWith('/admin/parking') || path == '/admin/dashboard';
    }

    // 5. FLIGHT MANAGER (Havayolu, Havalimanı, Gate + Dashboard)
    if (_currentRole == UserRole.flightManager) {
      return path.startsWith('/admin/airlines') ||
          path.startsWith('/admin/airports') ||
          path.startsWith('/admin/gates') ||
          path == '/admin/dashboard' ||
          path == '/admin/flights' ||
          path.startsWith('/admin/flight-crew');
    }

    // 6. AIRPORT MANAGER (Kullanıcı, Uçuş, Rezervasyon, Çalışanlar + Dashboard)
    if (_currentRole == UserRole.airportManager) {
      // İzin verilen modüllerin listesi:
      bool isUserMgmt = path.startsWith('/admin/users') || path.startsWith('/admin/roles');

      bool isFlightMgmt = path.startsWith('/admin/flights') || path.startsWith('/admin/aircrafts') ||
          path.startsWith('/admin/seats') || path.startsWith('/admin/flight-classes') ||
          path.startsWith('/admin/flight-pricing') || path.startsWith('/admin/flight-crew');


      bool isHrMgmt = path.startsWith('/admin/departments') || path.startsWith('/admin/employees');

      return isUserMgmt || isFlightMgmt || isHrMgmt || path == '/admin/dashboard';
    }

    // Tanımsız bir rol veya yetkisiz alan
    return false;
  }
}
