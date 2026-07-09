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

  AppLifecycleState? _lastLifecycleState;
  bool _isInBackground = false;
  Timer? _backgroundTimer;

  // Status koneksi internet
  bool _isOffline = false;

  // Debounce: cegah log duplikat dalam window 2 detik
  final Map<String, DateTime> _lastLogTime = {};
  static const Duration _dedupWindow = Duration(seconds: 2);

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

      if (result == ConnectivityResult.none) {
        _logEvent(eventType: 'DISCONNECTED');

        // Update state dan tampilkan peringatan
        if (mounted) {
          setState(() => _isOffline = true);
          _showOfflineWarning();
        }
      } else {
        _logEvent(eventType: 'RECONNECTED');

        // Koneksi kembali — sembunyikan banner dan retry pending submit jika ada
        if (mounted) {
          setState(() => _isOffline = false);
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Koneksi internet kembali'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Trigger retry pending submit jika ada
          ref.read(quizNotifierProvider).retryPendingSubmit();
        }
      }
    });
  }

  void _showOfflineWarning() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Koneksi Terputus!',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Internet Anda terputus saat mengerjakan kuis.\n\n'
          'Anda masih bisa melanjutkan mengerjakan soal, '
          'tetapi jawaban tidak akan tersimpan sampai koneksi kembali.\n\n'
          'Aktivitas ini telah dicatat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mengerti, Lanjutkan'),
          ),
        ],
      ),
    );
  }

  // ===============================
  // DISPOSE
  // ===============================
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectionSubscription.cancel();
    _backgroundTimer?.cancel();
    super.dispose();
  }

  // ===============================
  // DEDUP LOG HELPER
  // Cegah event yang sama dikirim dalam window 2 detik
  // ===============================
  void _logEvent({
    required String eventType,
    int? durationInSeconds,
    bool suspiciousFlag = false,
  }) {
    final now = DateTime.now();
    final last = _lastLogTime[eventType];
    if (last != null && now.difference(last) < _dedupWindow) return;
    _lastLogTime[eventType] = now;

    ref.read(quizLogServiceProvider).logEvent(
          eventType: eventType,
          exerciseId: widget.exerciseId,
          timestamp: now,
          durationInSeconds: durationInSeconds,
          suspiciousFlag: suspiciousFlag,
        );
  }

  // ===============================
  // LIFECYCLE MONITORING (FIXED)
  // ===============================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final nav = NavigationService.instance;
    if (!nav.isQuizLocked) return;

    // Hindari duplicate lifecycle state
    if (_lastLifecycleState == state) return;
    _lastLifecycleState = state;

    // =========================
    // MASUK BACKGROUND
    // =========================
    if (state == AppLifecycleState.paused) {
      // Jangan paksa kembali jika quiz sudah selesai
      final submitted = ref.read(quizNotifierProvider).submitted;
      if (submitted) return;

      if (_isInBackground) return;
      _isInBackground = true;

      // Simpan di singleton agar tidak hilang saat widget di-dispose
      nav.quizBackgroundTime = DateTime.now();

      _logEvent(eventType: 'APP_BACKGROUND');

      // HAPUS forceBackToQuiz — biarkan user kembali manual
      // forceBackToQuiz saat app di background menyebabkan crash/freeze
    }

    // =========================
    // KEMBALI KE APLIKASI
    // =========================
    if (state == AppLifecycleState.resumed) {
      // Cek dari singleton — bisa dari screen lama yang sudah di-dispose
      final bgTime = nav.quizBackgroundTime;
      if (bgTime == null) return;

      _backgroundTimer?.cancel();
      _isInBackground = false;
      nav.quizBackgroundTime = null;

      final duration = DateTime.now().difference(bgTime);

      // Suspicious jika keluar lebih dari 5 detik
      _logEvent(
        eventType: 'APP_RESUME',
        durationInSeconds: duration.inSeconds,
        suspiciousFlag: duration.inSeconds > 5,
      );

      // Tampilkan peringatan jika keluar cukup lama (suspicious)
      if (duration.inSeconds > 5 && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Text('Peringatan!'),
              content: Text(
                'Anda keluar dari aplikasi selama ${duration.inSeconds} detik. '
                'Aktivitas ini telah dicatat.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Mengerti'),
                ),
              ],
            ),
          );
        });
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
    final notifier = ref.watch(quizNotifierProvider);
    final nav = NavigationService.instance;

    // Saat quiz sudah selesai, izinkan back secara normal
    final canPop = notifier.submitted || !nav.isQuizLocked;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          if (context.mounted) {
            final navigator = Navigator.of(context);
            if (!navigator.canPop()) {
              navigator.pushNamedAndRemoveUntil('/home', (route) => false);
            }
          }
          return;
        }

        await _showWarningPopup();
        _logEvent(eventType: 'BACK_BUTTON_BLOCKED');
      },
      child: Column(
        children: [
          // Banner offline — tampil selama koneksi putus
          if (_isOffline)
            Material(
              color: Colors.red.shade700,
              child: const SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tidak ada koneksi internet — jawaban belum tersimpan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: QuizView(exerciseId: widget.exerciseId)),
        ],
      ),
    );
  }
}
