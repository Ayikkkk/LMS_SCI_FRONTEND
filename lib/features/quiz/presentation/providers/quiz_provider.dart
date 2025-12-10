// lib/features/quiz/presentation/providers/quiz_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/quiz_notifier.dart';
import '../../data/quiz_repository.dart' show IQuizRepository;
import '../../data/remote_quiz_repository.dart';

/// Expose repository as IQuizRepository so QuizNotifier always receives the
/// expected interface. Ensure RemoteQuizRepository implements IQuizRepository.
final quizRepositoryProvider = Provider<IQuizRepository>((ref) {
  final remote = ref.read(remoteQuizRepositoryProvider);
  return remote;
});

/// ChangeNotifier provider for QuizNotifier (autoDispose to free resources).
final quizNotifierProvider =
    ChangeNotifierProvider.autoDispose<QuizNotifier>((ref) {
  final repo = ref.read(quizRepositoryProvider);
  return QuizNotifier(repository: repo);
});
