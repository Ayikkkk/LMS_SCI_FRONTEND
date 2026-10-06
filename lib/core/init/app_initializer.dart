import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../network/api_client.dart';
import '../../features/auth/domain/auth_notifier.dart';
import '../utils/logger.dart';

final appInitializerProvider = FutureProvider<void>((ref) async {
  AppLogger.info('Starting app initialization', 'AppInitializer');

  try {
    await _initialize(ref);
    AppLogger.success('App initialization completed', 'AppInitializer');
  } catch (e, s) {
    // Jangan rethrow — jika init gagal, anggap unauthenticated
    // agar splash bisa navigate ke login
    AppLogger.error('App initialization failed, fallback to unauthenticated', e,
        s, 'AppInitializer');
    // Pastikan auth state di-set ke unauthenticated
    try {
      ref.read(authNotifierProvider.notifier).forceUnauthenticated();
    } catch (_) {}
  }
});

Future<void> _initialize(Ref ref) async {
  // Init Dio + Token
  await configureDio(
    onUnauthorized: () {
      ref.read(authNotifierProvider.notifier).doLogout();
    },
  );

  // Locale Indonesia
  await initializeDateFormatting('id_ID', null);

  // Cek session login
  final authNotifier = ref.read(authNotifierProvider.notifier);
  await authNotifier.checkAuthStatus();
}
