// lib/core/network/api_client.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ===============================================
// KONFIGURASI BASE URL API LARAVEL
// ===============================================
const String baseUrl = "http://192.168.1.13:8000/api/";

// ===============================================
// INISIALISASI DIO (HTTP CLIENT)
// ===============================================

final dio = Dio(
  BaseOptions(
    // Menggunakan base URL yang sudah didefinisikan
    baseUrl: baseUrl,

    // Waktu tunggu koneksi maksimal 30 detik
    connectTimeout: const Duration(seconds: 30),

    // Waktu tunggu respons data maksimal 30 detik
    receiveTimeout: const Duration(seconds: 30),

    // Header default (misalnya, untuk memberitahu server bahwa kita mengirim JSON)
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ),
);


// ===============================================
// INISIALISASI SECURE STORAGE
// ===============================================

// Instance FlutterSecureStorage untuk menyimpan token dan data sensitif
const FlutterSecureStorage storage = FlutterSecureStorage();

// Fungsi untuk memuat token dari secure storage dan mengatur header Authorization di Dio
Future<void> initializeDioToken() async {
  final token = await storage.read(key: 'auth_token');
  if (token != null) {
    dio.options.headers['Authorization'] = 'Bearer $token';
    print("Token loaded into Dio: $token");
  } else {
    print("No token found in secure storage.");
  }
}