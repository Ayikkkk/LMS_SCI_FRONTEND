// lib/features/quiz/presentation/quiz_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../screens/quiz_view.dart';
import '../../../../navigation_service.dart';
import '../providers/quiz_provider.dart';
import '../../data/quiz_log_service.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String exerciseId;

  const QuizScreen({
    super.key,
    required this.exerciseId,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen>
    with WidgetsBindingObserver {
  // ===============================
  // STATE VARIABLES
  // ===============================

  DateTime? _backgroundTime;
  AppLifecycleState? _lastLifecycleState;
  bool _isInBackground = false;

  late StreamSubscription<ConnectivityResult> _connectionSubscription;

  // ===============================
  // INIT
  // ===============================
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    NavigationService.instance.currentExerciseId = widget.exerciseId;

    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectionSubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      if (!NavigationService.instance.isQuizLocked) return;

      final logService = ref.read(quizLogServiceProvider);

      if (result == ConnectivityResult.none) {
        logService.logEvent(
          eventType: "DISCONNECTED",
          exerciseId: widget.exerciseId,
          timestamp: DateTime.now(),
        );
      } else {
        logService.logEvent(
          eventType: "RECONNECTED",
          exerciseId: widget.exerciseId,
          timestamp: DateTime.now(),
        );
      }
    });
  }

  // ===============================
  // DISPOSE
  // ===============================
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectionSubscription.cancel();
    super.dispose();
  }

  // ===============================
  // LIFECYCLE MONITORING (FIXED)
  // ===============================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final nav = NavigationService.instance;
    if (!nav.isQuizLocked) return;

    final logService = ref.read(quizLogServiceProvider);

    // Hindari duplicate lifecycle state
    if (_lastLifecycleState == state) return;
    _lastLifecycleState = state;

    // =========================
    // MASUK BACKGROUND
    // =========================
    if (state == AppLifecycleState.paused) {
      if (_isInBackground) return;
      _isInBackground = true;

      _backgroundTime = DateTime.now();

      logService.logEvent(
        eventType: "APP_BACKGROUND",
        exerciseId: widget.exerciseId,
        timestamp: _backgroundTime!,
      );

      // Paksa kembali ke quiz
      Future.delayed(const Duration(milliseconds: 300), () {
        nav.forceBackToQuiz();
      });
    }

    // =========================
    // KEMBALI KE APLIKASI
    // =========================
    if (state == AppLifecycleState.resumed) {
      if (!_isInBackground) return;
      _isInBackground = false;

      final now = DateTime.now();

      if (_backgroundTime != null) {
        final duration = now.difference(_backgroundTime!);

        logService.logEvent(
          eventType: "APP_RESUME",
          exerciseId: widget.exerciseId,
          timestamp: now,
          durationInSeconds: duration.inSeconds,
          suspiciousFlag: duration.inSeconds > 5,
        );
      }
    }
  }

  // ===============================
  // WARNING POPUP
  // ===============================
  Future<void> _showWarningPopup() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text(
          "Tidak Bisa Keluar!",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Anda harus menyelesaikan quiz sebelum keluar halaman ini.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Mengerti"),
          ),
        ],
      ),
    );
  }

  // ===============================
  // BUILD
  // ===============================
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final notifier = ref.read(quizNotifierProvider);
        final nav = NavigationService.instance;

        // Check if can pop
        final canPop = notifier.submitted || !nav.isQuizLocked;

        if (canPop) {
          // Allow navigation
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        } else {
          // Block and show warning
          await _showWarningPopup();

          final logService = ref.read(quizLogServiceProvider);
          logService.logEvent(
            eventType: "BACK_BUTTON_BLOCKED",
            exerciseId: widget.exerciseId,
            timestamp: DateTime.now(),
          );
        }
      },
      child: QuizView(exerciseId: widget.exerciseId),
    );
  }
}
