// lib/features/quiz/presentation/exercise_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/constants/error_messages.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/utils/logger.dart';
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
  ConsumerState<ExerciseListScreen> createState() => _ExerciseListScreenState();
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
        _error = ErrorMessages.fromException(e);
      });
      AppLogger.error('Error fetch exercises', e, st, 'ExerciseListScreen');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _buildTile(Map<String, dynamic> ex) {
    final isDone = ex['is_done'] == true;
    final isPending = ex['is_pending_review'] == true;
    final isLocked = ex['is_locked'] == true;
    final score = ex['score'];

    // Kuis terkunci — tampilkan berbeda
    if (isLocked) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade100,
          child:
              Icon(Icons.lock_outline, color: Colors.grey.shade500, size: 20),
        ),
        title: Text(
          ex['title'] ?? 'Ulangan',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipe: ${ex["exercise_type"]?["name"] ?? widget.typeName}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 12, color: Colors.grey.shade400),
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
            ),
          ],
        ),
        trailing: Icon(Icons.lock, color: Colors.grey.shade300, size: 18),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔒 Kuis ini belum dibuka oleh guru'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        },
      );
    }

    // Status badge untuk kuis terbuka
    Widget? badge;
    if (isPending) {
      badge = const _StatusBadge(
        label: 'Menunggu Nilai',
        color: Colors.orange,
        icon: Icons.pending_outlined,
      );
    } else if (isDone && score != null) {
      badge = _StatusBadge(
        label: 'Nilai: $score',
        color: Colors.green,
        icon: Icons.check_circle_outline,
      );
    } else if (isDone) {
      badge = const _StatusBadge(
        label: 'Sudah Dikerjakan',
        color: Colors.green,
        icon: Icons.check_circle_outline,
      );
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: isDone
            ? Colors.green.shade50
            : Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          isDone ? Icons.check : Icons.quiz_outlined,
          color: isDone ? Colors.green : Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        ex['title'] ?? 'Ulangan',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipe: ${ex["exercise_type"]?["name"] ?? widget.typeName}',
            style: const TextStyle(fontSize: 12),
          ),
          if (badge != null) ...[
            const SizedBox(height: 4),
            badge,
          ],
        ],
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDone ? Colors.green : null,
      ),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuizRemoteScreen(exerciseId: ex['id'].toString()),
          ),
        );
        _fetchExercises();
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
              ? AppErrorWidget(
                  message: _error!,
                  onRetry: _fetchExercises,
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

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
