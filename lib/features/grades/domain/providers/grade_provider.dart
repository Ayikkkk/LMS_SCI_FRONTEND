import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/recap_score_model.dart';
import '../../data/repository/grade_repository.dart';
import '../../../../core/constants/error_messages.dart';
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
  final String? downloadedPdfPath; // path file untuk OpenFilex

  const GradeState({
    this.isLoading = false,
    this.error,
    this.recap,
    this.downloadedPdfPath,
  });

  GradeState copyWith({
    bool? isLoading,
    String? error,
    RecapScoreModel? recap,
    String? downloadedPdfPath,
  }) {
    return GradeState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      recap: recap ?? this.recap,
      downloadedPdfPath: downloadedPdfPath ?? this.downloadedPdfPath,
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
        error: ErrorMessages.fromException(e),
      );
    }
  }

  /// ============================
  /// Download PDF Rekap
  /// ============================
  Future<bool> downloadPdf() async {
    if (state.isLoading) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final path = await _repository.downloadRecapPdf();

      state = state.copyWith(
        isLoading: false,
        downloadedPdfPath: path,
      );

      return path != null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorMessages.fromException(e),
      );
      return false;
    }
  }
}

/// ============================
/// Public Provider
/// ============================
final gradeProvider = StateNotifierProvider<GradeNotifier, GradeState>((ref) {
  final repository = ref.read(gradeRepositoryProvider);
  return GradeNotifier(repository);
});
