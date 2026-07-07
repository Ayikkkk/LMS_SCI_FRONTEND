// lib/features/quiz/presentation/providers/quiz_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/quiz_notifier.dart';
import '../../data/quiz_repository.dart' show IQuizRepository;
import '../../data/remote_quiz_repository.dart';
import '../../data/quiz_log_service.dart';
import '../../data/quiz_cache_service.dart';

final quizRepositoryProvider = Provider<IQuizRepository>((ref) {
  return ref.read(remoteQuizRepositoryProvider);
});

/// ChangeNotifierProvider for QuizNotifier — autoDispose agar timer dan resource
/// dibebaskan saat halaman kuis ditutup. Tanpa autoDispose, timer berjalan selamanya
/// di background untuk setiap kuis yang pernah dibuka.
final quizNotifierProvider =
    ChangeNotifierProvider.autoDispose<QuizNotifier>((ref) {
  final repo = ref.read(quizRepositoryProvider);
  final logSvc = ref.read(quizLogServiceProvider);
  final cacheSvc = ref.read(quizCacheServiceProvider);
  return QuizNotifier(
      repository: repo, logService: logSvc, cacheService: cacheSvc);
});
