import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import '../config/app_config.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final auth = ref.watch(authControllerProvider);
  return ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    accessToken: auth.accessToken,
    onUnauthorized: () =>
        ref.read(authControllerProvider.notifier).refreshAccessToken(),
  );
});

class ApiClient {
  ApiClient({
    required String baseUrl,
    String? accessToken,
    Future<String?> Function()? onUnauthorized,
  }) : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Accept': 'application/json'},
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // A retry carries the refreshed token via extra; otherwise use the
          // token captured at construction.
          final token = options.extra['access_token'] as String? ?? accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final alreadyRetried = error.requestOptions.extra['retried'] == true;
          if (!isUnauthorized || alreadyRetried || onUnauthorized == null) {
            handler.next(error);
            return;
          }

          final newToken = await onUnauthorized();
          if (newToken == null || newToken.isEmpty) {
            handler.next(error);
            return;
          }

          final retryOptions = error.requestOptions
            ..extra['retried'] = true
            ..extra['access_token'] = newToken;
          try {
            final retryResponse = await dio.fetch<dynamic>(retryOptions);
            handler.resolve(retryResponse);
          } on DioException catch (retryError) {
            handler.next(retryError);
          }
        },
      ),
    );
  }

  final Dio dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, Object?>? queryParameters,
  }) {
    return dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
  }) {
    return dio.post<T>(path, data: data, queryParameters: queryParameters);
  }

  Future<Response<T>> patch<T>(String path, {Object? data}) {
    return dio.patch<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) {
    return dio.delete<T>(path);
  }
}
