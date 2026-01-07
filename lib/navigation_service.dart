// lib/navigation_service.dart

import 'package:flutter/material.dart';
import 'features/quiz/presentation/screens/quiz_screen.dart';

class NavigationService {
  NavigationService._private();
  static final NavigationService instance = NavigationService._private();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  bool isQuizLocked = false;
  String? currentExerciseId;

  final List<void Function(NavigatorState)> _pending = [];

  bool get isReady => navigatorKey.currentState != null;

  // ============================
  // QUEUE HANDLER
  // ============================
  void runOrQueue(void Function(NavigatorState navigator) action) {
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      action(navigator);
    } else {
      _pending.add(action);
    }
  }

  void flushPending() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    for (final action in List.from(_pending)) {
      action(navigator);
    }
    _pending.clear();
  }

  // ============================
  // FORCE BACK TO QUIZ
  // ============================
  void forceBackToQuiz() {
    if (currentExerciseId == null) return;

    runOrQueue((navigator) {
      final currentRoute = ModalRoute.of(navigator.context);

      // Sudah berada di halaman quiz → jangan push ulang
      if (currentRoute?.settings.name == "quiz_${currentExerciseId!}") {
        return;
      }

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          settings: RouteSettings(name: "quiz_${currentExerciseId!}"),
          builder: (_) => QuizScreen(exerciseId: currentExerciseId!),
        ),
        (route) => false,
      );
    });
  }

  // ============================
  // SAFE PUSH
  // ============================
  void safePush(Widget page) {
    runOrQueue((navigator) {
      // Jika sedang terkunci, hanya boleh pindah ke QuizScreen
      if (isQuizLocked && page is! QuizScreen) {
        return;
      }

      navigator.push(
        MaterialPageRoute(
          settings: RouteSettings(
            name: page is QuizScreen
                ? "quiz_${page.exerciseId}"
                : page.runtimeType.toString(),
          ),
          builder: (_) => page,
        ),
      );
    });
  }
}
