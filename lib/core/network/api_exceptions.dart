import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final data = response?.data;

    if (data is Map<String, Object?> && data['message'] is String) {
      return ApiException(
        data['message'] as String,
        statusCode: response?.statusCode,
      );
    }

    if (data is Map<String, Object?>) {
      final nestedError = data['error'];
      if (nestedError is Map<String, Object?> &&
          nestedError['message'] is String) {
        return ApiException(
          nestedError['message'] as String,
          statusCode: response?.statusCode,
        );
      }

      final detail = data['detail'];
      if (detail is String) {
        return ApiException(detail, statusCode: response?.statusCode);
      }
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map<String, Object?> && first['msg'] is String) {
          return ApiException(
            first['msg'] as String,
            statusCode: response?.statusCode,
          );
        }
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const ApiException('Kết nối tới server quá lâu.');
      case DioExceptionType.badResponse:
        return ApiException(
          'Server trả về lỗi ${response?.statusCode ?? ''}.'.trim(),
          statusCode: response?.statusCode,
        );
      case DioExceptionType.cancel:
        return const ApiException('Yêu cầu đã bị hủy.');
      case DioExceptionType.connectionError:
        return const ApiException('Không thể kết nối tới server.');
      case DioExceptionType.badCertificate:
        return const ApiException('Chứng chỉ server không hợp lệ.');
      case DioExceptionType.unknown:
        return const ApiException('Có lỗi mạng không xác định.');
    }
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
