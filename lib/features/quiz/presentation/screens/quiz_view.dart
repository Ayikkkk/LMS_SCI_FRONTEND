import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/environment.dart';
import '../../domain/quiz_notifier.dart';
import '../../domain/models/question_model.dart';
import '../providers/quiz_provider.dart';
import '../widgets/question_widgets.dart';

class QuizView extends ConsumerWidget {
  final String exerciseId;

  const QuizView({
    super.key,
    required this.exerciseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(quizNotifierProvider);

    // LOADING STATE
    if (notifier.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // RESULT STATE
    if (notifier.submitted) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              final navigator = Navigator.of(context);
              if (navigator.canPop()) {
                navigator.pop();
              } else {
                navigator.pushNamedAndRemoveUntil('/home', (route) => false);
              }
            },
          ),
          title: const Text("Hasil Quiz"),
        ),
        body: Column(
          children: [
            Expanded(child: _buildResult(context, notifier)),
            // Tombol home selalu tampil — penting saat stack kosong (auto-submit)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/home', (route) => false),
                  icon: const Icon(Icons.home),
                  label: const Text('Kembali ke Beranda'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // EMPTY QUESTIONS
    if (notifier.questions.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text("Soal belum tersedia", style: TextStyle(fontSize: 18)),
        ),
      );
    }

    // QUIZ SCREEN
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz Berlangsung"),
        automaticallyImplyLeading: false,
      ),
      // Jangan resize saat keyboard muncul — mencegah overflow pada EssayWidget
      // EssayWidget menggunakan SingleChildScrollView sendiri
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          // Banner pending submit — tampil jika submit sebelumnya gagal karena network
          if (notifier.hasPendingSubmit)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: Colors.orange.shade100,
              child: const Row(
                children: [
                  Icon(Icons.cloud_off, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Jawaban tersimpan lokal. Akan dikirim ulang saat koneksi pulih.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildQuestion(context, notifier, ref)),
        ],
      ),
    );
  }

  // ================= QUESTION VIEW =================
  Widget _buildQuestion(
      BuildContext context, QuizNotifier notifier, WidgetRef ref) {
    if (notifier.totalQuizSeconds != QuizNotifier.noTimeLimit &&
        notifier.remainingSeconds <= 0 &&
        !notifier.submitted) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              "Waktu habis!\nMengirim hasil kuis...",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    final question = notifier.questions[notifier.currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // TIMER — hanya widget ini yang rebuild setiap detik
        const _QuizTimerWidget(),

        // CONTENT — tidak rebuild saat timer tick
        Expanded(
          child: _QuizQuestionContent(
            question: question,
            currentIndex: notifier.currentIndex,
            totalQuestions: notifier.questions.length,
            notifier: notifier,
            onPrevious: notifier.previous,
            onNext: notifier.next,
            onSubmit: () => notifier.submit(context: context),
            onJumpTo: (index) {
              final diff = index - notifier.currentIndex;
              if (diff > 0) {
                for (var j = 0; j < diff; j++) {
                  notifier.next();
                }
              } else if (diff < 0) {
                for (var j = 0; j > diff; j--) {
                  notifier.previous();
                }
              }
            },
            allAnswered: notifier.allAnswered,
            selectedAnswers: notifier.selectedAnswers,
            onShowUnansweredSnackbar: (unanswered, firstUnansweredIndex) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '$unanswered soal belum dijawab. '
                    'Selesaikan semua soal terlebih dahulu.',
                  ),
                  action: SnackBarAction(
                    label: 'Lihat',
                    onPressed: () {
                      final diff = firstUnansweredIndex - notifier.currentIndex;
                      if (diff > 0) {
                        for (var j = 0; j < diff; j++) {
                          notifier.next();
                        }
                      } else if (diff < 0) {
                        for (var j = 0; j > diff; j--) {
                          notifier.previous();
                        }
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ================= RESULT VIEW =================
  Widget _buildResult(BuildContext context, QuizNotifier notifier) {
    // Jika pending review (menunggu penilaian guru)
    if (notifier.isPendingReview) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pending_actions, size: 90, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              "Quiz Terkirim",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Menunggu Penilaian Guru",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Jawaban Anda sedang ditinjau oleh guru. Nilai akan muncul setelah guru selesai menilai.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            if (notifier.exerciseTypeName != null) ...[
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tipe: ${notifier.exerciseTypeName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Jika pending submit (network gagal, jawaban tersimpan lokal)
    if (notifier.hasPendingSubmit &&
        notifier.finalScore == null &&
        !notifier.isPendingReview) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_upload_outlined,
                size: 90, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              "Jawaban Tersimpan",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Koneksi terputus saat mengirim.",
              style: TextStyle(fontSize: 16, color: Colors.orange),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Jawaban sudah disimpan. Akan dikirim otomatis saat koneksi kembali.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    // Jika sudah ada nilai
    // Guard: jika finalScore masih null tapi bukan pending submit dan bukan pending review,
    // berarti getResult() masih in-flight (window ~500ms setelah submit sukses)
    // atau retryPendingSubmit() baru selesai submit tapi belum fetch result.
    // Tampilkan loading daripada string "null".
    if (notifier.finalScore == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Mengambil hasil...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // finalScore sudah tersedia
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 90, color: Colors.green),
          const SizedBox(height: 16),
          const Text(
            "Hasil Quiz",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            "Nilai: ${notifier.finalScore}",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Quiz hanya bisa dikerjakan sekali.",
            style: TextStyle(color: Colors.grey),
          ),
          if (notifier.exerciseTypeName != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Tipe: ${notifier.exerciseTypeName}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================
// _QuizTimerWidget — hanya watch remainingSeconds & totalQuizSeconds
// Widget ini yang rebuild setiap detik, bukan seluruh tree
// =============================================================
class _QuizTimerWidget extends ConsumerWidget {
  const _QuizTimerWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remainingSeconds =
        ref.watch(quizNotifierProvider.select((n) => n.remainingSeconds));
    final totalQuizSeconds =
        ref.watch(quizNotifierProvider.select((n) => n.totalQuizSeconds));

    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      color: totalQuizSeconds == QuizNotifier.noTimeLimit
          ? (isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50)
          : (isDarkMode ? Colors.red.shade900 : Colors.red.shade50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Sisa Waktu",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          totalQuizSeconds == QuizNotifier.noTimeLimit
              ? Text(
                  "Tidak ada batas",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDarkMode ? Colors.lightBlue : Colors.blue,
                  ),
                )
              : Text(
                  "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: remainingSeconds <= 60
                        ? Colors.red
                        : (isDarkMode ? Colors.white : Colors.black87),
                  ),
                ),
        ],
      ),
    );
  }
}

// =============================================================
// _QuizQuestionContent — StatelessWidget biasa, tidak watch notifier
// Menerima semua data sebagai parameter sehingga TIDAK rebuild tiap detik
// =============================================================
class _QuizQuestionContent extends StatelessWidget {
  final QuestionModel question;
  final int currentIndex;
  final int totalQuestions;
  final QuizNotifier notifier;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;
  final void Function(int index) onJumpTo;
  final bool allAnswered;
  final Map<String, dynamic> selectedAnswers;
  final void Function(int unanswered, int firstUnansweredIndex)
      onShowUnansweredSnackbar;

  const _QuizQuestionContent({
    required this.question,
    required this.currentIndex,
    required this.totalQuestions,
    required this.notifier,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
    required this.onJumpTo,
    required this.allAnswered,
    required this.selectedAnswers,
    required this.onShowUnansweredSnackbar,
  });

  @override
  Widget build(BuildContext context) {
    // Tablet: tambah padding horizontal agar teks soal tidak melebar penuh
    // HP: padding tetap 0 karena layar sudah sempit
    final hPad = MediaQuery.of(context).size.width > 700
        ? (MediaQuery.of(context).size.width - 700) / 2
        : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // QUESTION TEXT — render HTML jika ada gambar, fallback ke teks biasa
          if (question.questionHtml != null &&
              question.questionHtml!.contains('<'))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                "Soal ${currentIndex + 1} / $totalQuestions",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                "Soal ${currentIndex + 1} / $totalQuestions",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ),

          // Konten soal — dibatasi tinggi agar tidak overflow
          if (question.questionHtml != null &&
              question.questionHtml!.contains('<'))
            RepaintBoundary(
              key: ValueKey('html_${question.id}'),
              child: _QuestionHtmlContent(html: question.questionHtml!),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                _cleanQuestionText(question.question),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),

          // ANSWER OPTIONS
          Expanded(
            child: _buildQuestionWidget(question, notifier),
          ),

          // NAVIGATION BUTTONS
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              children: [
                // ── Indikator soal ─────────────────────────────────
                _QuestionIndicator(notifier: notifier),
                const SizedBox(height: 10),
                // ── Tombol navigasi ────────────────────────────────
                Row(
                  children: [
                    if (currentIndex > 0)
                      ElevatedButton(
                        onPressed: onPrevious,
                        child: const Text("Sebelumnya"),
                      ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        if (currentIndex == totalQuestions - 1) {
                          // Soal terakhir → cek semua sudah dijawab
                          if (allAnswered) {
                            onSubmit();
                          } else {
                            // Hitung berapa yang belum dijawab
                            final unanswered = notifier.questions
                                .where(
                                    (q) => !selectedAnswers.containsKey(q.id))
                                .length;
                            final firstUnansweredIndex = notifier.questions
                                .indexWhere(
                                    (q) => !selectedAnswers.containsKey(q.id));
                            onShowUnansweredSnackbar(
                                unanswered, firstUnansweredIndex);
                          }
                        } else {
                          // Bisa lanjut ke soal berikutnya meski belum dijawab
                          onNext();
                        }
                      },
                      child: Text(
                        currentIndex == totalQuestions - 1
                            ? "Selesai"
                            : "Selanjutnya",
                      ),
                    ),
                  ],
                ),
              ],
            ), // closes Column (navigation)
          ), // closes Padding (navigation)
        ], // closes outer Column children
      ), // closes outer Column
    ); // closes outer Padding (tablet)
  }

  // ================= QUESTION WIDGET BUILDER =================
  Widget _buildQuestionWidget(QuestionModel question, QuizNotifier notifier) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return MultipleChoiceWidget(question: question, notifier: notifier);

      case QuestionType.multipleAnswer:
        return MultipleAnswerWidget(question: question, notifier: notifier);

      case QuestionType.trueFalse:
        return TrueFalseWidget(question: question, notifier: notifier);

      case QuestionType.yesNo:
        return YesNoWidget(question: question, notifier: notifier);

      case QuestionType.shortAnswer:
      case QuestionType.fillInTheBlank:
        return ShortAnswerWidget(
          key: ValueKey('short_${question.id}'),
          question: question,
          notifier: notifier,
        );

      case QuestionType.essay:
        return EssayWidget(
          key: ValueKey('essay_${question.id}'),
          question: question,
          notifier: notifier,
        );
    }
  }

  // ================= HELPER: Clean Question Text =================
  String _cleanQuestionText(String text) {
    // Replace literal "/n /n" or "/n" with actual newlines
    String cleaned = text
        .replaceAll('/n /n', '\n\n')
        .replaceAll('/n', '\n')
        .replaceAll('\\n', '\n');
    return cleaned;
  }
}

/// Widget untuk menampilkan konten soal HTML.
class _QuestionHtmlContent extends StatelessWidget {
  final String html;
  const _QuestionHtmlContent({required this.html});

  /// Ekstrak semua src dari tag <img> dalam HTML
  static List<String> _extractImageUrls(String html) {
    final regex = RegExp(r'<img[^>]+src="([^"]+)"', caseSensitive: false);
    return regex
        .allMatches(html)
        .map((m) => m.group(1) ?? '')
        .where((url) => url.isNotEmpty)
        .toList();
  }

  /// Hapus tag HTML, kembalikan teks bersih
  static String _stripTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = _extractImageUrls(html);
    final text = _stripTags(html);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gambar soal — dibatasi tinggi maxHeight dari parent ConstrainedBox
          ...imageUrls.map((url) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _SslBypassImage(key: ValueKey(url), url: url),
                ),
              )),
          // Teks soal
          if (text.isNotEmpty)
            Text(
              text,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}

/// Indikator dot per soal — hijau=dijawab, merah=belum, biru=saat ini
class _QuestionIndicator extends StatelessWidget {
  final QuizNotifier notifier;
  const _QuestionIndicator({required this.notifier});

  @override
  Widget build(BuildContext context) {
    final total = notifier.questions.length;
    final answered = notifier.selectedAnswers.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ringkasan teks
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            '$answered / $total soal dijawab',
            style: TextStyle(
              fontSize: 12,
              color: answered == total ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Dot grid
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(total, (i) {
            final question = notifier.questions[i];
            final isAnswered =
                notifier.selectedAnswers.containsKey(question.id);
            final isCurrent = i == notifier.currentIndex;

            Color dotColor;
            if (isCurrent) {
              dotColor = Colors.blue;
            } else if (isAnswered) {
              dotColor = Colors.green;
            } else {
              dotColor = Colors.red.shade300;
            }

            return GestureDetector(
              onTap: () {
                // Navigasi langsung ke soal yang diklik
                final diff = i - notifier.currentIndex;
                if (diff > 0) {
                  for (var j = 0; j < diff; j++) {
                    notifier.next();
                  }
                } else if (diff < 0) {
                  for (var j = 0; j > diff; j--) {
                    notifier.previous();
                  }
                }
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(color: Colors.blue.shade900, width: 2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Widget gambar yang menggunakan WebView untuk bypass TLS issues.
/// WebView menggunakan Chrome's TLS stack yang support semua cipher suite.
class _SslBypassImage extends StatefulWidget {
  final String url;
  const _SslBypassImage({super.key, required this.url});

  /// Cache statis dengan batas maksimal 30 gambar — cegah memory leak saat banyak soal
  static final Map<String, Uint8List> _cache = {};
  static const int _maxCacheSize = 30;

  static void _addToCache(String url, Uint8List bytes) {
    if (_cache.length >= _maxCacheSize) {
      // Hapus entry pertama (oldest) saat cache penuh
      _cache.remove(_cache.keys.first);
    }
    _cache[url] = bytes;
  }

  @override
  State<_SslBypassImage> createState() => _SslBypassImageState();
}

class _SslBypassImageState extends State<_SslBypassImage> {
  late Future<List<int>> _imageFuture;

  @override
  void initState() {
    super.initState();
    if (_SslBypassImage._cache.containsKey(widget.url)) {
      _imageFuture = Future.value(_SslBypassImage._cache[widget.url]!.toList());
    } else {
      _imageFuture = _fetchImage(widget.url);
    }
  }

  Future<List<int>> _fetchImage(String url) async {
    // Proxy URL via backend siswa
    final base =
        EnvironmentConfig.apiBaseUrl.replaceAll(RegExp(r'/api/?$'), '');
    final proxyUrl = '$base/api/proxy-image?url=${Uri.encodeComponent(url)}';

    try {
      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      httpClient.connectionTimeout = const Duration(seconds: 10);

      final request = await httpClient.getUrl(Uri.parse(proxyUrl));
      request.headers.set('Accept', 'image/*');
      final response =
          await request.close().timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
        }
        httpClient.close();
        if (bytes.isNotEmpty) {
          _SslBypassImage._addToCache(url, Uint8List.fromList(bytes));
          return bytes;
        }
      }
      httpClient.close();
    } catch (e) {
      debugPrint('🖼️ Proxy failed: $e');
    }

    throw Exception('Image not available: $url');
  }

  @override
  Widget build(BuildContext context) {
    final cached = _SslBypassImage._cache[widget.url];
    if (cached != null) {
      return Image.memory(
        cached,
        width: double.infinity,
        height: 160,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildError(),
      );
    }

    return FutureBuilder<List<int>>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 80,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 6),
                  Text('Memuat gambar...', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return Image.memory(
            Uint8List.fromList(snapshot.data!),
            width: double.infinity,
            height: 160,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _buildError(),
          );
        }

        // Proxy gagal — coba langsung via Image.network
        return Image.network(
          widget.url,
          width: double.infinity,
          height: 160,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildError(),
        );
      },
    );
  }

  Widget _buildError() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.image_not_supported_outlined,
                  color: Colors.orange.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gambar soal tidak dapat dimuat otomatis.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Baca teks soal di bawah untuk menjawab pertanyaan.',
            style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
          ),
        ],
      ),
    );
  }
}
