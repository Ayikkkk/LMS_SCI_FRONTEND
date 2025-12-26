import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../network/api_client.dart';

final appInitializerProvider = FutureProvider<void>((ref) async {
  try {
    // 🚀 Inisialisasi interceptor token DIO
    await configureDio();

    // 🌍 Inisialisasi format tanggal lokal Indonesia
    await initializeDateFormatting('id_ID', null);

    print("🔥 App initialization completed");
  } catch (e, s) {
    print("❌ Error during app initialization: $e");
    print(s);
  }
});
