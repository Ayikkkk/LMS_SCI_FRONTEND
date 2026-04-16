import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../network/api_client.dart';
import '../../features/auth/domain/auth_notifier.dart';
import '../utils/logger.dart';

final appInitializerProvider = FutureProvider<void>((ref) async {
  try {
    AppLogger.info('Starting app initialization', 'AppInitializer');

    // Init Dio + Token
    // On 401, auto-logout and redirect to login
    await configureDio(
      onUnauthorized: () {
        ref.read(authNotifierProvider.notifier).doLogout();
      },
    );

    //Locale Indonesia
    await initializeDateFormatting('id_ID', null);

    // CEK SESSION LOGIN
    final authNotifier = ref.read(authNotifierProvider.notifier);
    await authNotifier.checkAuthStatus();

    AppLogger.success('App initialization completed', 'AppInitializer');
  } catch (e, s) {
    AppLogger.error('App initialization failed', e, s, 'AppInitializer');
    rethrow;
  }
});
