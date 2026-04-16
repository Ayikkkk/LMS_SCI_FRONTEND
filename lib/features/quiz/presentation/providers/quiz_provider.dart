// lib/features/quiz/presentation/providers/quiz_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/quiz_notifier.dart';
import '../../data/quiz_repository.dart' show IQuizRepository;
import '../../data/remote_quiz_repository.dart';
import '../../data/quiz_log_service.dart';

final quizRepositoryProvider = Provider<IQuizRepository>((ref) {
  return ref.read(remoteQuizRepositoryProvider);
});

/// ChangeNotifier provider for QuizNotifier (autoDispose to free resources).
final quizNotifierProvider = ChangeNotifierProvider<QuizNotifier>((ref) {
  final repo = ref.read(quizRepositoryProvider);
  final logSvc = ref.read(quizLogServiceProvider);
  return QuizNotifier(repository: repo, logService: logSvc);
});
