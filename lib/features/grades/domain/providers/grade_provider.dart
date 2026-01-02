import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/recap_score_model.dart';
import '../../data/repository/grade_repository.dart';
import '../../../../core/network/api_client.dart';

/// ============================
/// Repository Provider
/// ============================
final gradeRepositoryProvider = Provider<GradeRepository>((ref) {
  final dio = ref.read(apiClientProvider);
  return GradeRepository(dio);
});

/// ============================
/// State
/// ============================
class GradeState {
  final bool isLoading;
  final String? error;
  final RecapScoreModel? recap;
  final File? downloadedPdf;

  const GradeState({
    this.isLoading = false,
    this.error,
    this.recap,
    this.downloadedPdf,
  });

  GradeState copyWith({
    bool? isLoading,
    String? error,
    RecapScoreModel? recap,
    File? downloadedPdf,
  }) {
    return GradeState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      recap: recap ?? this.recap,
      downloadedPdf: downloadedPdf ?? this.downloadedPdf,
    );
  }
}

/// ============================
/// Notifier
/// ============================
class GradeNotifier extends StateNotifier<GradeState> {
  final GradeRepository _repository;

  GradeNotifier(this._repository) : super(const GradeState());

  /// ============================
  /// Load rekap nilai
  /// ============================
  Future<void> loadRecap() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final recap = await _repository.fetchRecapPerMapel();
      state = state.copyWith(
        isLoading: false,
        recap: recap,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// ============================
  /// Download PDF Rekap
  /// ============================
  Future<File?> downloadPdf() async {
    if (state.isLoading) return null;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final file = await _repository.downloadRecapPdf();

      state = state.copyWith(
        isLoading: false,
        downloadedPdf: file,
      );

      return file;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }
}

/// ============================
/// Public Provider
/// ============================
final gradeProvider =
    StateNotifierProvider<GradeNotifier, GradeState>((ref) {
  final repository = ref.read(gradeRepositoryProvider);
  return GradeNotifier(repository);
});
