// lib/core/network/api_client.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/environment.dart';
import '../utils/logger.dart';

// Get API configuration from environment
String get apiHost => EnvironmentConfig.apiHost;
String get apiBaseUrl => EnvironmentConfig.apiBaseUrl;

// Dio dibuat tanpa baseUrl dulu — akan di-set saat configureDio() dipanggil
final Dio dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Accept': 'application/json',
    },
  ),
);

const FlutterSecureStorage storage = FlutterSecureStorage();

//  TOKEN INTERCEPTOR
class TokenInterceptor extends Interceptor {
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storage.read(key: 'auth_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }
}

/// Interceptor that catches 401 responses and triggers logout via callback.
/// Sanctum stateless tokens cannot be refreshed, so on 401 we clear storage
/// and notify the app to redirect to login.
class AuthExpiredInterceptor extends Interceptor {
  final void Function() onUnauthorized;
  bool _isHandling = false;

  AuthExpiredInterceptor({required this.onUnauthorized});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Jika tidak ada token sama sekali, ini bukan expired session
      // (bisa terjadi saat provider masih firing setelah logout)
      final token = await storage.read(key: 'auth_token');
      if (token == null || token.isEmpty) {
        return handler.next(err);
      }

      // Cegah double-trigger
      if (_isHandling) return handler.next(err);
      _isHandling = true;

      AppLogger.warning(
        'Token expired or invalid — clearing session',
        'AuthExpiredInterceptor',
      );
      await storage.delete(key: 'auth_token');
      await storage.delete(key: 'student_data');
      dio.options.headers.remove('Authorization');
      onUnauthorized();

      _isHandling = false;
    }
    return handler.next(err);
  }
}

//  Configure Dio with interceptors
Future<void> configureDio({void Function()? onUnauthorized}) async {
  // Set baseUrl dan timeout SETELAH EnvironmentConfig.initialize() dipanggil
  dio.options.baseUrl = EnvironmentConfig.apiBaseUrl;
  dio.options.connectTimeout = EnvironmentConfig.connectTimeout;
  dio.options.receiveTimeout = EnvironmentConfig.receiveTimeout;

  dio.interceptors.clear();
  dio.interceptors.add(TokenInterceptor());

  if (onUnauthorized != null) {
    dio.interceptors.add(
      AuthExpiredInterceptor(onUnauthorized: onUnauthorized),
    );
  }

  // Add logging interceptor in non-production environments
  if (EnvironmentConfig.enableDebugFeatures) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      logPrint: (obj) => AppLogger.debug(obj.toString(), 'Dio'),
    ));
  }

  AppLogger.info(
    'Dio configured for ${EnvironmentConfig.environmentName} environment',
    'ApiClient',
  );
  AppLogger.info('Base URL: $apiBaseUrl', 'ApiClient');
}

final apiClientProvider = Provider<Dio>((ref) {
  return dio;
});
