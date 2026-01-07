// lib/core/network/api_client.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String apiHost = "http://192.168.110.49:8000";
const String apiBaseUrl = "$apiHost/api/";

final Dio dio = Dio(
  BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Accept': 'application/json',
    },
  ),
);

const FlutterSecureStorage storage = FlutterSecureStorage();

// 🚀 TOKEN INTERCEPTOR
class TokenInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storage.read(key: 'auth_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }
}

// 🔥 Pasang interceptor saat init
Future<void> configureDio() async {
  dio.interceptors.clear();
  dio.interceptors.add(TokenInterceptor());
}

final apiClientProvider = Provider<Dio>((ref) {
  return dio;
});
