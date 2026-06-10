import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/auth_provider.dart';
import 'core/config/theme.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/splash_screen.dart';
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

      // Still restoring a remembered session — hold on the splash ('/').
      if (authState.isRestoring) {
        return location == '/' ? null : '/';
      }

      if (!authState.isAuthenticated) {
        // Auth screens are reachable; the splash and protected routes bounce
        // to login once the session check has finished.
        final canStay =
            location == '/login' ||
            location == '/register' ||
            location == '/forgot-password';
        return canStay ? null : '/login';
      }

      // Authenticated — keep users off the splash and login screens.
      if (location == '/' || location == '/login') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) =>
            const _BackScope(parent: '/login', child: RegisterScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) =>
            const _BackScope(parent: '/login', child: ForgotPasswordScreen()),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/pairing',
        builder: (context, state) =>
            const _BackScope(parent: '/home', child: ScanScreen()),
      ),
      GoRoute(
        path: '/devices/:deviceId',
        builder: (context, state) {
          return _BackScope(
            parent: '/home',
            child: DeviceDetailScreen(
              deviceId: state.pathParameters['deviceId']!,
            ),
          );
        },
      ),
      GoRoute(
        path: '/devices/:deviceId/sharing',
        builder: (context, state) {
          final deviceId = state.pathParameters['deviceId']!;
          return _BackScope(
            parent: '/devices/$deviceId',
            child: DeviceSharingScreen(deviceId: deviceId),
          );
        },
      ),
      GoRoute(
        path: '/devices/:deviceId/admin-ble',
        builder: (context, state) {
          final deviceId = state.pathParameters['deviceId']!;
          return _BackScope(
            parent: '/devices/$deviceId',
            child: AdminBleScreen(deviceId: deviceId),
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) =>
            const _BackScope(parent: '/home', child: AppSettingsScreen()),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) =>
            const _BackScope(parent: '/home', child: ProfileScreen()),
      ),
    ],
  );
});

/// Routes the Android system back button to a screen's logical parent.
///
/// Every in-app navigation uses `context.go()`, which replaces the router
/// stack — so without this the system back button (or back gesture) would find
/// an empty history and exit the app from any screen. [PopScope] intercepts the
/// pop and redirects to [parent], mirroring each screen's `LuniAppBar.onBack`.
/// Root screens (`/login`, `/home`) don't wrap, so back there still exits.
class _BackScope extends StatelessWidget {
  const _BackScope({required this.parent, required this.child});

  final String parent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(parent);
      },
      child: child,
    );
  }
}

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
