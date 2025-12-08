import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// --- LAYOUTLAR ---
import '../shared/layouts/admin_layout.dart';
import '../shared/layouts/checkin_layout.dart';
import '../shared/layouts/parking_layout.dart';

// --- GENEL EKRANLAR ---
import '../features/auth/login_screen.dart';

// --- DASHBOARDLAR ---
import '../features/admin/dashboard/admin_dashboard_screen.dart';
import '../features/checkin/dashboard/checkin_dashboard_screen.dart';
import '../features/parking/dashboard/parking_dashboard_screen.dart';

// --- ADMIN MODÜLÜ SAYFALARI ---
import '../features/admin/users/users_screen.dart';
import '../features/admin/roles/roles_screen.dart';
import '../features/admin/activity-log/activity_log_screen.dart';
import '../features/admin/airlines/airlines_screen.dart';
import '../features/admin/airports/airports_screen.dart';
import '../features/admin/flight-classes/flight_classes_screen.dart';
import '../features/admin/aircrafts/aircrafts_screen.dart';
import '../features/admin/flights/flights_screen.dart';
import '../features/admin/seats/seats_screen.dart';
import '../features/admin/flight-pricing/flight_pricing_screen.dart';
import '../features/admin/flight-crew/flight_crew_screen.dart';
import '../features/admin/reservations/reservations_screen.dart';
import '../features/admin/reservations/reservation_detail_screen.dart';
import '../features/admin/passengers/passengers_screen.dart';
import '../features/admin/departments/departments_screen.dart';
import '../features/admin/employees/employees_screen.dart';
import '../features/admin/gates/gates_screen.dart';

// Admin - Otopark Yönetimi
import '../features/admin/parking/vehicle-types/vehicle_types_screen.dart';
import '../features/admin/parking/lots/parking_lots_screen.dart' as AdminLots;
import '../features/admin/parking/spots/parking_spots_screen.dart';
import '../features/admin/parking/user-vehicles/user_vehicles_screen.dart';
import '../features/admin/parking/reservations/parking_reservations_screen.dart' as AdminRes;
import '../features/admin/parking/payments/payments_screen.dart' as AdminPay;

// --- CHECK-IN MODÜLÜ SAYFALARI ---
import '../features/checkin/tickets/checkin_tickets_screen.dart';
import '../features/checkin/passengers/checkin_passengers_screen.dart';

// --- PARKING (OPERASYON) MODÜLÜ SAYFALARI ---
import '../features/parking/entry-exit/entry_exit_screen.dart';
import '../features/parking/parking-lots-list/parking_lots_list_screen.dart';
import '../features/parking/parking-lots-detail/parking_lot_detail_screen.dart';
import '../features/parking/parking-reservations/parking_reservations_screen.dart' as OpsRes;
import '../features/parking/payments/payments_list_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    // ----------------------------------------------------------------
    // 1. AUTH ROTASI
    // ----------------------------------------------------------------
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    // ----------------------------------------------------------------
    // 2. ADMIN PANELİ
    // ----------------------------------------------------------------
    ShellRoute(
      builder: (context, state, child) => AdminLayout(child: child),
      routes: [
        GoRoute(path: '/admin/dashboard', builder: (context, state) => const AdminDashboardScreen()),

        // Kullanıcılar
        GoRoute(path: '/admin/users', builder: (context, state) => const UsersScreen()),
        GoRoute(path: '/admin/roles', builder: (context, state) => const RolesScreen()),
        GoRoute(path: '/admin/activity-log', builder: (context, state) => const ActivityLogScreen()),

        // Uçuş Yönetimi
        GoRoute(path: '/admin/airlines', builder: (context, state) => const AirlinesScreen()),
        GoRoute(path: '/admin/airports', builder: (context, state) => const AirportsScreen()),
        GoRoute(path: '/admin/flight-classes', builder: (context, state) => const FlightClassesScreen()),
        GoRoute(path: '/admin/aircrafts', builder: (context, state) => const AircraftsScreen()),
        GoRoute(path: '/admin/flights', builder: (context, state) => const FlightsScreen()),
        GoRoute(path: '/admin/seats', builder: (context, state) => const SeatsScreen()),
        GoRoute(path: '/admin/flight-pricing', builder: (context, state) => const FlightPricingScreen()),
        GoRoute(path: '/admin/flight-crew', builder: (context, state) => const FlightCrewScreen()),

        // Rezervasyon & Bilet (Admin)
        GoRoute(path: '/admin/reservations', builder: (context, state) => const ReservationsScreen()),
        GoRoute(
          path: '/admin/reservations/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ReservationDetailScreen(reservationId: id);
          },
        ),
        GoRoute(path: '/admin/passengers', builder: (context, state) => const PassengersScreen()),

        // İnsan Kaynakları
        GoRoute(path: '/admin/departments', builder: (context, state) => const DepartmentsScreen()),
        GoRoute(path: '/admin/employees', builder: (context, state) => const EmployeesScreen()),

        // Havalimanı
        GoRoute(path: '/admin/gates', builder: (context, state) => const GatesScreen()),

        // Otopark Yönetimi (Admin)
        GoRoute(path: '/admin/parking/vehicle-types', builder: (context, state) => const VehicleTypesScreen()),
        GoRoute(path: '/admin/parking/lots', builder: (context, state) => const AdminLots.ParkingLotsScreen()),
        GoRoute(path: '/admin/parking/spots', builder: (context, state) => const ParkingSpotsScreen()),
        GoRoute(path: '/admin/parking/user-vehicles', builder: (context, state) => const UserVehiclesScreen()),
        GoRoute(path: '/admin/parking/reservations', builder: (context, state) => const AdminRes.ParkingReservationsScreen()),
        GoRoute(path: '/admin/parking/payments', builder: (context, state) => const AdminPay.PaymentsScreen()),
      ],
    ),

    // ----------------------------------------------------------------
    // 3. CHECK-IN PANELİ
    // ----------------------------------------------------------------
    ShellRoute(
      builder: (context, state, child) => CheckInLayout(child: child),
      routes: [
        GoRoute(path: '/checkin/dashboard', builder: (context, state) => const CheckInDashboardScreen()),
        GoRoute(path: '/checkin/tickets', builder: (context, state) => const CheckInTicketsScreen()),
        GoRoute(path: '/checkin/passengers', builder: (context, state) => const CheckInPassengersScreen()),
      ],
    ),

    // ----------------------------------------------------------------
    // 4. PARKING (OPERASYON) PANELİ
    // ----------------------------------------------------------------
    ShellRoute(
      builder: (context, state, child) => ParkingLayout(child: child),
      routes: [
        GoRoute(path: '/parking/dashboard', builder: (context, state) => const ParkingDashboardScreen()),

        // Giriş/Çıkış İşlemleri
        GoRoute(path: '/parking/entry-exit', builder: (context, state) => const EntryExitScreen()),

        // Otopark Listesi ve Detayı
        GoRoute(path: '/parking/parking-lots-list', builder: (context, state) => const ParkingLotsListScreen()),
        GoRoute(
          path: '/parking/parking-lot-detail',
          builder: (context, state) {
            final name = state.uri.queryParameters['name'] ?? 'Otopark';
            final airport = state.uri.queryParameters['airport'] ?? 'Havalimanı';
            return ParkingLotDetailScreen(lotName: name, airportName: airport);
          },
        ),

        // Rezervasyon ve Ödemeler (Operasyonel)
        GoRoute(path: '/parking/reservations', builder: (context, state) => const OpsRes.ParkingReservationsScreen()),
        GoRoute(path: '/parking/payments-list', builder: (context, state) => const PaymentsListScreen()),
      ],
    ),
  ],
);