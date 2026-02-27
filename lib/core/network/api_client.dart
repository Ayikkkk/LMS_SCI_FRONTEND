// lib/core/network/api_client.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/environment.dart';
import '../utils/logger.dart';

// Get API configuration from environment
String get apiHost => EnvironmentConfig.apiHost;
String get apiBaseUrl => EnvironmentConfig.apiBaseUrl;

final Dio dio = Dio(
  BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: EnvironmentConfig.connectTimeout,
    receiveTimeout: EnvironmentConfig.receiveTimeout,
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

//  Configure Dio with interceptors
Future<void> configureDio() async {
  dio.interceptors.clear();
  dio.interceptors.add(TokenInterceptor());

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
