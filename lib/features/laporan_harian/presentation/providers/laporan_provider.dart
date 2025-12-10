import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/laporan_repository.dart';

/// Provider cek laporan hari ini
final laporanCheckProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final repo = ref.read(laporanRepositoryProvider);
  return repo.isFilledToday();
});
