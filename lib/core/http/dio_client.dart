import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../api_config.dart';
import '../utils/app_logger.dart';
import '../../data/auth/token_storage.dart';
import '../../data/api/api_exception.dart';

typedef OnSessionExpiredCallback = void Function();

class DioClient {
  static final DioClient instance = DioClient._internal();

  late final Dio dio;
  final TokenStorage tokenStorage = TokenStorage();
  OnSessionExpiredCallback? onSessionExpired;

  bool _isRefreshing = false;

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        connectTimeout: ApiConfig.timeout,
        receiveTimeout: ApiConfig.timeout,
        sendTimeout: ApiConfig.timeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Security rule: reject http in release builds
          if (kReleaseMode && options.uri.scheme == 'http') {
            return handler.reject(
              DioException(
                requestOptions: options,
                error: ApiException('Insecure HTTP base URL rejected in release build. Use HTTPS.'),
              ),
            );
          }

          // Attach token if not a login request
          final isLogin = options.path.contains(ApiConfig.defaultLoginPath);
          if (!isLogin) {
            final token = await tokenStorage.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers[ApiConfig.authHeaderKey] =
                  '${ApiConfig.authScheme} $token';
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          final uri = response.requestOptions.uri;
          final path = uri.path;
          final method = response.requestOptions.method;
          final code = response.statusCode;
          int? count;
          final data = response.data;
          if (data is Map && data['data'] is List) {
            count = (data['data'] as List).length;
          }
          final summary = count != null ? '($count items)' : 'OK';
          AppLogger.instance.api(method, path, code, summary);
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          final uri = error.requestOptions.uri;
          final path = uri.path;
          final method = error.requestOptions.method;
          final statusCode = error.response?.statusCode;
          final msg = error.message ?? error.error?.toString() ?? 'Error';
          AppLogger.instance.api(
            method,
            path,
            statusCode,
            msg,
            error.response?.data?.toString(),
          );

          if (statusCode == 401 || statusCode == 403) {
            final isLogin = error.requestOptions.path.contains(ApiConfig.defaultLoginPath);
            if (!isLogin && !_isRefreshing) {
              _isRefreshing = true;
              try {
                final refreshed = await _tryRefreshToken();
                if (refreshed) {
                  _isRefreshing = false;
                  // Retry the original request
                  final newOptions = error.requestOptions;
                  final newToken = await tokenStorage.getAccessToken();
                  newOptions.headers[ApiConfig.authHeaderKey] =
                      '${ApiConfig.authScheme} $newToken';
                  final response = await dio.fetch(newOptions);
                  return handler.resolve(response);
                }
              } catch (_) {}
              _isRefreshing = false;

              // Session expired
              onSessionExpired?.call();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }
    // Placeholder refresh logic if server provides refresh endpoint
    return false;
  }

  ApiException handleDioError(dynamic error) {
    if (error is ApiException) return error;
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return ApiException('Connection timeout. Please check your internet or server status.',
            statusCode: 408, originalError: error);
      }
      if (error.type == DioExceptionType.connectionError) {
        return ApiException('Cannot connect to server. Please check host URL and Wi-Fi.',
            statusCode: 503, originalError: error);
      }
      final res = error.response;
      if (res != null) {
        final data = res.data;
        if (data is Map && data['message'] != null) {
          return ApiException(data['message'].toString(),
              statusCode: res.statusCode, originalError: error);
        }
        return ApiException('Server responded with error (${res.statusCode})',
            statusCode: res.statusCode, originalError: error);
      }
      return ApiException(error.message ?? 'Network error occurred', originalError: error);
    }
    return ApiException(error.toString(), originalError: error);
  }
}
