// lib/core/network/api_client.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ===============================================
// 1. KONFIGURASI BASE URL API LARAVEL
// ===============================================
const String baseUrl = "http://10.200.209.158:8000/api/";

// ===============================================
// 2. INISIALISASI DIO (HTTP CLIENT)
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
// 3. INISIALISASI SECURE STORAGE
// ===============================================

// Instance FlutterSecureStorage untuk menyimpan token dan data sensitif
const FlutterSecureStorage storage = FlutterSecureStorage();