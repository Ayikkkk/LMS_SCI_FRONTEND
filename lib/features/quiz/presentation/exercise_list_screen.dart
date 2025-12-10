// lib/features/quiz/presentation/exercise_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'quiz_remote_screen.dart';

class ExerciseListScreen extends ConsumerStatefulWidget {
  final String lessonId;
  final String lessonName;
  final String typeId;
  final String typeName;

  const ExerciseListScreen({
    super.key,
    required this.lessonId,
    required this.lessonName,
    required this.typeId,
    required this.typeName,
  });

  @override
  ConsumerState<ExerciseListScreen> createState() =>
      _ExerciseListScreenState();
}

class _ExerciseListScreenState extends ConsumerState<ExerciseListScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _exercises = [];

  @override
  void initState() {
    super.initState();
    _fetchExercises();
  }

  Future<void> _fetchExercises() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final Dio dio = ref.read(apiClientProvider);

    try {
      final response = await dio.get(
        "student/lesson/${widget.lessonId}/exercises",
        queryParameters: {
          "type_id": widget.typeId,
        },
      );

      setState(() {
        _exercises = response.data["data"] ?? [];
      });
    } catch (e, st) {
      setState(() {
        _error = e.toString();
      });
      debugPrint("Error fetch exercises: $e\n$st");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _buildTile(Map<String, dynamic> ex) {
    return ListTile(
      title: Text(ex["title"] ?? "Ulangan"),
      subtitle: Text(
        "Tipe: ${ex["exercise_type"]?["name"] ?? widget.typeName}",
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                QuizRemoteScreen(exerciseId: ex["id"].toString()),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.lessonName} — ${widget.typeName}"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Error: $_error"),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _fetchExercises,
                        child: const Text("Coba lagi"),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _exercises.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) =>
                      _buildTile(_exercises[i] as Map<String, dynamic>),
                ),
    );
  }
}
