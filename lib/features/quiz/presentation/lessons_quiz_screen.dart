// lib/features/quiz/presentation/lessons_quiz_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
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
    } on DioError catch (dioErr) {
      // Jika request dibatalkan, jangan tampilkan error
      if (dioErr.type == DioErrorType.cancel) {
        // ignore canceled request
        return;
      }

      if (mounted) {
        setState(() {
          _error = dioErr.message;
        });
      }
      debugPrint("ERR LessonsQuizScreen (Dio): $dioErr");
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
      debugPrint("ERR LessonsQuizScreen: $e\n$st");
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
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                ...types.map((t) {
                  return ListTile(
                    leading: const Icon(Icons.quiz),
                    title: Text(t["name"]),
                    subtitle: Text("${t["count"]} latihan tersedia"),
                    onTap: () {
                      // gunakan sheetContext untuk pop agar jelas kita tutup bottom sheet
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
                }).toList(),

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
                  color: Colors.blueAccent,
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
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Text(
                          "Kelas ${lesson["grade"]} • Sem ${lesson["semester"]}",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54),
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
      appBar: AppBar(
        title: const Text("Pilih Mapel & Tipe Ujian"),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLessons,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Text("Error: $_error"),
                        ),
                      )
                    ],
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
