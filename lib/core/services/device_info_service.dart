// lib/core/services/device_info_service.dart

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deviceInfoServiceProvider = Provider<DeviceInfoService>((ref) {
  return DeviceInfoService();
});

class DeviceInfoService {
  static String? _cached;

  /// Mengembalikan string ringkas info perangkat, contoh:
  /// Android: "Samsung Galaxy A52 | Android 13 (SDK 33)"
  /// iOS:     "iPhone 14 Pro | iOS 17.2"
  Future<String> getDeviceInfo() async {
    if (_cached != null) return _cached!;

    try {
      final plugin = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        _cached =
            '${info.manufacturer} ${info.model} | Android ${info.version.release} (SDK ${info.version.sdkInt})';
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        _cached =
            '${info.name} ${info.model} | ${info.systemName} ${info.systemVersion}';
      } else {
        _cached = 'Unknown Platform';
      }
    } catch (_) {
      _cached = 'Unknown Device';
    }

    return _cached!;
  }
}
