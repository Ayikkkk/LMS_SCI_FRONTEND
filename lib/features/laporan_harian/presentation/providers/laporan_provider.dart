import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/laporan_repository.dart';

/// Mengecek apakah hari ini sudah mengisi laporan
final laporanCheckProvider = FutureProvider<bool>((ref) async {
  final repo = ref.read(laporanRepositoryProvider);
  return repo.isFilledToday();
});
