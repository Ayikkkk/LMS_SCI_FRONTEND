import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../network/api_client.dart';

final appInitializerProvider = FutureProvider<void>((ref) async {
  // Inisialisasi token dio
  await initializeDioToken();

  // Inisialisasi locale
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    print("Locale init gagal: $e");
  }
});
 