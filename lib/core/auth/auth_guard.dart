import 'auth_provider.dart';

bool canAccessProtectedRoute(AuthState state) {
  return state.isAuthenticated;
}

String? protectedRouteRedirect(AuthState state, String location) {
  if (!state.isAuthenticated && location != '/login') {
    return '/login';
  }

  return null;
}
