// lib/features/quiz/presentation/lessons_quiz_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/constants/error_messages.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/utils/logger.dart';
import 'exercise_list_screen.dart';

class LessonsQuizScreen extends ConsumerStatefulWidget {
  const LessonsQuizScreen({super.key});

  @override
  ConsumerState<LessonsQuizScreen> createState() => _LessonsQuizScreenState();
}

class _LessonsQuizScreenState extends ConsumerState<LessonsQuizScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _lessons = [];

  // Cancel token untuk membatalkan request saat dispose
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _cancelToken = CancelToken();
    _fetchLessons();
  }

  @override
  void dispose() {
    // batalkan request jika masih berlangsung
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel("Disposed");
    }
    super.dispose();
  }

  Future<void> _fetchLessons() async {
    // set loading hanya jika masih mounted
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final dio = ref.read(apiClientProvider);

    try {
      final resp = await dio.get(
        "student/exercise-lessons",
        cancelToken: _cancelToken,
      );

      if (!mounted) return; // safety: jika sudah tidak mounted, hentikan

      setState(() {
        _lessons = resp.data["data"] ?? [];
      });
    } on DioException catch (dioErr) {
      // Jika request dibatalkan, jangan tampilkan error
      if (dioErr.type == DioExceptionType.cancel) {
        return;
      }

      if (mounted) {
        setState(() {
          _error = ErrorMessages.fromDioException(dioErr);
        });
      }
      AppLogger.error(
        'LessonsQuizScreen (Dio)',
        dioErr,
        null,
        'LessonsQuizScreen',
      );
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _error = ErrorMessages.fromException(e);
        });
      }
      AppLogger.error('LessonsQuizScreen', e, st, 'LessonsQuizScreen');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _openTypesSheet(Map<String, dynamic> lesson) {
    final types = (lesson["types"] ?? []) as List<dynamic>;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson["name"],
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                ...types.map((t) {
                  final total = (t["count"] ?? 0) as int;
                  final done = (t["done_count"] ?? 0) as int;
                  final pending = (t["pending_count"] ?? total - done) as int;
                  final isLocked = (t["is_locked"] ?? false) as bool;

                  return ListTile(
                    leading: Icon(
                      isLocked ? Icons.lock_outline : Icons.quiz,
                      color: isLocked
                          ? Colors.grey
                          : Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      t["name"],
                      style: TextStyle(color: isLocked ? Colors.grey : null),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$total latihan tersedia",
                          style: TextStyle(
                              color: isLocked ? Colors.grey.shade400 : null),
                        ),
                        const SizedBox(height: 4),
                        if (isLocked)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline,
                                  size: 12, color: Colors.grey.shade400),
                              const SizedBox(width: 3),
                              Text(
                                'Belum dibuka oleh guru',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade400,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              _StatusChip(
                                label: "$done selesai",
                                color: Colors.green,
                                icon: Icons.check_circle_outline,
                              ),
                              const SizedBox(width: 6),
                              _StatusChip(
                                label: "$pending belum",
                                color:
                                    pending > 0 ? Colors.orange : Colors.grey,
                                icon: Icons.pending_outlined,
                              ),
                            ],
                          ),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: isLocked
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('🔒 Kuis ini belum dibuka oleh guru'),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        : () {
                            Navigator.pop(sheetContext);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExerciseListScreen(
                                  lessonId: lesson["id"].toString(),
                                  lessonName: lesson["name"],
                                  typeId: t["id"].toString(),
                                  typeName: t["name"],
                                ),
                              ),
                            );
                          },
                  );
                }),
                if (types.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Tidak ada tipe latihan untuk mapel ini."),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLessonCard(Map<String, dynamic> lesson) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _openTypesSheet(lesson),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson["name"] ?? "",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          "Kelas ${lesson["grade"]} • Sem ${lesson["semester"]}",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchLessons,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? AppErrorWidget(
                    message: _error!,
                    onRetry: _fetchLessons,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _lessons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final lesson = _lessons[i] as Map<String, dynamic>;
                      return _buildLessonCard(lesson);
                    },
                  ),
      ),
    );
  }
}

/// Chip kecil untuk status selesai / belum
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
