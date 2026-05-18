import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/teknisi/dashboard_teknisi_screen.dart';
import '../screens/teknisi/ticket_list_screen.dart';
import '../screens/teknisi/ticket_detail_screen.dart';
import '../screens/teknisi/odp_map_screen.dart';
import '../screens/teknisi/attendance_screen.dart';
import '../screens/teknisi/profile_teknisi_screen.dart';
import '../screens/customer/dashboard_customer_screen.dart';
import '../providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggingIn = state.matchedLocation == '/login';
      final isSplash = state.matchedLocation == '/';

      if (authState.isLoading) return null;

      if (!authState.isAuthenticated && !isLoggingIn && !isSplash) {
        return '/login';
      }

      if (authState.isAuthenticated && (isLoggingIn || isSplash)) {
        if (authState.role == 'customer') {
          return '/customer/dashboard';
        } else if (authState.role == 'teknisi') {
          return '/teknisi/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      // Role Teknisi Routes
      GoRoute(
        path: '/teknisi/dashboard',
        builder: (context, state) => const DashboardTeknisiScreen(),
      ),
      GoRoute(
        path: '/teknisi/tickets',
        builder: (context, state) => const TicketListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return TicketDetailScreen(ticketId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/teknisi/map-odp',
        builder: (context, state) => const OdpMapScreen(),
      ),
      GoRoute(
        path: '/teknisi/map-customer',
        builder: (context, state) => const OdpMapScreen(), // Reuse map for now or custom
      ),
      GoRoute(
        path: '/teknisi/attendance',
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: '/teknisi/profile',
        builder: (context, state) => const ProfileTeknisiScreen(),
      ),
      // Role Customer Routes
      GoRoute(
        path: '/customer/dashboard',
        builder: (context, state) => const DashboardCustomerScreen(),
      ),
    ],
  );
});
