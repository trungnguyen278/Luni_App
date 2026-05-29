import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/auth_provider.dart';
import 'core/config/theme.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/device/screens/device_detail_screen.dart';
import 'features/device/screens/device_sharing_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/pairing/screens/admin_ble_screen.dart';
import 'features/pairing/screens/scan_screen.dart';
import 'features/settings/screens/app_settings_screen.dart';
import 'features/settings/screens/profile_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthRoute =
          location == '/' ||
          location == '/login' ||
          location == '/register' ||
          location == '/forgot-password';

      if (!authState.isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      if (authState.isAuthenticated &&
          (location == '/' || location == '/login')) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/pairing',
        builder: (context, state) => const ScanScreen(),
      ),
      GoRoute(
        path: '/devices/:deviceId',
        builder: (context, state) {
          return DeviceDetailScreen(
            deviceId: state.pathParameters['deviceId']!,
          );
        },
      ),
      GoRoute(
        path: '/devices/:deviceId/sharing',
        builder: (context, state) {
          return DeviceSharingScreen(
            deviceId: state.pathParameters['deviceId']!,
          );
        },
      ),
      GoRoute(
        path: '/devices/:deviceId/admin-ble',
        builder: (context, state) {
          return AdminBleScreen(deviceId: state.pathParameters['deviceId']!);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const AppSettingsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});

class LuniApp extends ConsumerWidget {
  const LuniApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Luni',
      debugShowCheckedModeBanner: false,
      theme: LuniTheme.darkTheme,
      routerConfig: router,
    );
  }
}
