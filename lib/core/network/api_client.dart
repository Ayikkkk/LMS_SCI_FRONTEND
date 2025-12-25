// lib/core/network/api_client.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===============================================
// BASE URL API
// ===============================================
const String apiHost = "http://192.168.110.45:8000";
const String apiBaseUrl = "$apiHost/api/";

// ===============================================
// DIO GLOBAL (API ONLY)
// ===============================================
final Dio dio = Dio(
  BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ),
);

// ===============================================
// STORAGE TOKEN
// ===============================================
const FlutterSecureStorage storage = FlutterSecureStorage();

// ===============================================
// LOAD TOKEN KE HEADER
// ===============================================
Future<void> initializeDioToken() async {
  final token = await storage.read(key: 'auth_token');
  if (token != null && token.isNotEmpty) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }
}

// ===============================================
// PROVIDER
// ===============================================
final apiClientProvider = Provider<Dio>((ref) => dio);
