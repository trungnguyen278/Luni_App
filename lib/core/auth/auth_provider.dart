import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../shared/models/user.dart';
import '../config/app_config.dart';
import '../network/api_exceptions.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

enum AuthStatus { unknown, unauthenticated, authenticating, authenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.error,
  });

  const AuthState.unknown() : this(status: AuthStatus.unknown);

  const AuthState.unauthenticated({String? error})
    : this(status: AuthStatus.unauthenticated, error: error);

  const AuthState.authenticating() : this(status: AuthStatus.authenticating);

  const AuthState.authenticated({
    required User user,
    required String accessToken,
    required String refreshToken,
  }) : this(
         status: AuthStatus.authenticated,
         user: user,
         accessToken: accessToken,
         refreshToken: refreshToken,
       );

  final AuthStatus status;
  final User? user;
  final String? accessToken;
  final String? refreshToken;
  final String? error;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  bool get isLoading => status == AuthStatus.authenticating;

  /// True until the stored session has been checked on launch — the router
  /// shows a splash instead of flashing the login screen for remembered users.
  bool get isRestoring => status == AuthStatus.unknown;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Restore a remembered session on first launch. Tokens live in secure
    // storage (written by [_applyTokenResponse]); the router holds on a splash
    // while status is `unknown`.
    Future.microtask(tryRestoreSession);
    return const AuthState.unknown();
  }

  Future<void> signIn({required String email, required String password}) async {
    final normalizedEmail = email.trim();

    if (normalizedEmail.isEmpty || password.isEmpty) {
      state = const AuthState.unauthenticated(
        error: 'Nhập email và mật khẩu để đăng nhập.',
      );
      return;
    }

    state = const AuthState.authenticating();
    await _signInWithApi(email: normalizedEmail, password: password);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AuthState.authenticating();
    await _registerWithApi(
      name: name.trim(),
      email: email.trim(),
      password: password,
    );
  }

  Future<void> forgotPassword({required String email}) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      state = const AuthState.unauthenticated(
        error: 'Nhập email để lấy lại mật khẩu.',
      );
      return;
    }

    state = const AuthState.authenticating();
    try {
      await _authDio().post<Map<String, Object?>>(
        '/auth/forgot-password',
        data: {'email': normalizedEmail},
      );
      state = const AuthState.unauthenticated(
        error: 'Đã gửi email khôi phục mật khẩu. Kiểm tra hộp thư.',
      );
    } on DioException catch (error) {
      final apiError = ApiException.fromDio(error);
      state = AuthState.unauthenticated(error: apiError.message);
    } on Object catch (error) {
      state = AuthState.unauthenticated(
        error: 'Gửi yêu cầu thất bại: $error',
      );
    }
  }

  /// Restore a remembered login from secure storage. Always resolves the state
  /// to a terminal value (`authenticated` or `unauthenticated`) so the launch
  /// splash never hangs.
  Future<void> tryRestoreSession() async {
    String? accessToken;
    String? refreshToken;
    try {
      final storage = ref.read(secureStorageProvider);
      accessToken = await storage
          .read(key: 'access_token')
          .timeout(const Duration(milliseconds: 500));
      refreshToken = await storage
          .read(key: 'refresh_token')
          .timeout(const Duration(milliseconds: 500));
    } catch (_) {
      // Secure storage unavailable (e.g. widget tests / early desktop shells).
    }

    if (refreshToken == null || refreshToken.isEmpty) {
      state = const AuthState.unauthenticated();
      return;
    }

    // 1) Try the stored access token directly.
    if (accessToken != null && accessToken.isNotEmpty) {
      final user = await _fetchMe(accessToken);
      if (user != null) {
        state = AuthState.authenticated(
          user: user,
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        return;
      }
    }

    // 2) Access token missing or expired → refresh, then retry.
    final newAccess = await _refreshWithToken(refreshToken);
    if (newAccess != null) {
      final user = await _fetchMe(newAccess);
      if (user != null) {
        state = AuthState.authenticated(
          user: user,
          accessToken: newAccess,
          refreshToken: refreshToken,
        );
        return;
      }
    }

    // Stored session is no longer valid — clear it and require re-login.
    await signOut();
  }

  /// Fetch the current user with [accessToken]. Returns null on any failure
  /// (rejected token, network error, malformed body).
  Future<User?> _fetchMe(String accessToken) async {
    try {
      final response = await _authDio().get<Map<String, Object?>>(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      final userJson = response.data?['user'] ?? response.data;
      if (userJson is Map<String, Object?>) {
        return User.fromJson(userJson);
      }
    } catch (_) {
      // Token rejected or network error.
    }
    return null;
  }

  /// Exchange [refreshToken] for a fresh access token (persisted on success).
  Future<String?> _refreshWithToken(String refreshToken) async {
    try {
      final response = await _authDio().post<Map<String, Object?>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final newAccess = response.data?['access_token'] as String?;
      if (newAccess != null && newAccess.isNotEmpty) {
        await _writeToken('access_token', newAccess);
        return newAccess;
      }
    } catch (_) {
      // Refresh token expired/revoked.
    }
    return null;
  }

  Future<void> signOut() async {
    await _deleteToken('access_token');
    await _deleteToken('refresh_token');
    state = const AuthState.unauthenticated();
  }

  Future<String?>? _refreshFuture;

  /// Exchange the stored refresh token for a fresh access token.
  ///
  /// Single-flight: concurrent 401s share one in-flight refresh. Returns the
  /// new access token, or null (and signs out) if refresh is impossible.
  Future<String?> refreshAccessToken() {
    return _refreshFuture ??=
        _doRefresh().whenComplete(() => _refreshFuture = null);
  }

  Future<String?> _doRefresh() async {
    var refreshToken = state.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      try {
        refreshToken = await ref
            .read(secureStorageProvider)
            .read(key: 'refresh_token')
            .timeout(const Duration(milliseconds: 300));
      } catch (_) {
        refreshToken = null;
      }
    }

    if (refreshToken == null || refreshToken.isEmpty) {
      await signOut();
      return null;
    }

    try {
      final response = await _authDio().post<Map<String, Object?>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final newAccess = response.data?['access_token'] as String?;
      if (newAccess == null || newAccess.isEmpty) {
        await signOut();
        return null;
      }

      await _writeToken('access_token', newAccess);
      final user = state.user;
      if (user != null) {
        state = AuthState.authenticated(
          user: user,
          accessToken: newAccess,
          refreshToken: refreshToken,
        );
      }
      return newAccess;
    } on Object {
      // Refresh token expired/revoked → force re-login.
      await signOut();
      return null;
    }
  }

  Future<void> _writeToken(String key, String value) async {
    try {
      await ref
          .read(secureStorageProvider)
          .write(key: key, value: value)
          .timeout(const Duration(milliseconds: 300));
    } on TimeoutException {
      // Widget tests and early desktop shells may not provide secure storage.
    } on PlatformException {
      // Widget tests and early desktop shells may not provide secure storage.
    }
  }

  Future<void> _deleteToken(String key) async {
    try {
      await ref
          .read(secureStorageProvider)
          .delete(key: key)
          .timeout(const Duration(milliseconds: 300));
    } on TimeoutException {
      // See _writeToken.
    } on PlatformException {
      // See _writeToken.
    }
  }

  Future<void> _signInWithApi({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _authDio().post<Map<String, Object?>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      await _applyTokenResponse(response.data ?? {});
    } on DioException catch (error) {
      final apiError = ApiException.fromDio(error);
      state = AuthState.unauthenticated(error: apiError.message);
    } on Object catch (error) {
      state = AuthState.unauthenticated(error: 'Đăng nhập thất bại: $error');
    }
  }

  Future<void> _registerWithApi({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _authDio().post<Map<String, Object?>>(
        '/auth/register',
        data: {'email': email, 'password': password, 'name': name},
      );
      await _applyTokenResponse(response.data ?? {});
    } on DioException catch (error) {
      final apiError = ApiException.fromDio(error);
      state = AuthState.unauthenticated(error: apiError.message);
    } on Object catch (error) {
      state = AuthState.unauthenticated(
        error: 'Tạo tài khoản thất bại: $error',
      );
    }
  }

  Dio _authDio() {
    return Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );
  }

  Future<void> _applyTokenResponse(Map<String, Object?> data) async {
    final userJson = data['user'];
    final accessToken = data['access_token'] as String?;
    final refreshToken = data['refresh_token'] as String?;

    if (userJson is! Map<String, Object?> ||
        accessToken == null ||
        refreshToken == null) {
      state = const AuthState.unauthenticated(
        error: 'Phản hồi đăng nhập không đúng định dạng.',
      );
      return;
    }

    final user = User.fromJson(userJson);
    await _writeToken('access_token', accessToken);
    await _writeToken('refresh_token', refreshToken);

    state = AuthState.authenticated(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
