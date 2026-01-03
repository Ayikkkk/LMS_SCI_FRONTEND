import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../network/api_client.dart';
import '../../features/auth/domain/auth_notifier.dart';

final appInitializerProvider = FutureProvider<void>((ref) async {
  try {
    // Init Dio + Token
    await configureDio();

    //Locale Indonesia
    await initializeDateFormatting('id_ID', null);

    // CEK SESSION LOGIN
    final authNotifier = ref.read(authNotifierProvider.notifier);
    await authNotifier.checkAuthStatus();

    print("App initialization completed");
  } catch (e, s) {
    print("Error during app initialization: $e");
    print(s);
  }
});
