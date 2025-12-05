// lib/core/network/api_client.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===============================================
// KONFIGURASI BASE URL API LARAVEL
// ===============================================
const String baseUrl = "http://192.168.1.9:8000/api/";

// ===============================================
// INISIALISASI DIO (HTTP CLIENT)
// ===============================================

final dio = Dio(
  BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ),
);

// ===============================================
// INISIALISASI SECURE STORAGE
// ===============================================

const FlutterSecureStorage storage = FlutterSecureStorage();

// Memasukkan token ke header Authorization
Future<void> initializeDioToken() async {
  final token = await storage.read(key: 'auth_token');
  if (token != null) {
    dio.options.headers['Authorization'] = 'Bearer $token';
    print("Token loaded into Dio: $token");
  } else {
    print("No token found in secure storage.");
  }
}

// ===============================================
// PROVIDER API CLIENT (WAJIB!)
// ===============================================

// Gunakan ini di seluruh aplikasi
final apiClientProvider = Provider<Dio>((ref) {
  return dio;
});
