import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/providers/grade_provider.dart';
import '../widgets/subject_section.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import 'package:open_filex/open_filex.dart';

class RecapGradeScreen extends ConsumerStatefulWidget {
  const RecapGradeScreen({super.key});

  @override
  ConsumerState<RecapGradeScreen> createState() => _RecapGradeScreenState();
}

class _RecapGradeScreenState extends ConsumerState<RecapGradeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(gradeProvider.notifier).loadRecap();
    });
  }

  Future<void> _downloadPdf() async {
    final notifier = ref.read(gradeProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      const SnackBar(
          content: Text('Mengunduh rekap nilai ke folder Download/LMS Student...')),
    );

    final success = await notifier.downloadPdf();

    if (!mounted) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'PDF berhasil diunduh ke folder Download/LMS Student'
              : 'Gagal mengunduh PDF',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gradeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Nilai'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Unduh PDF',
            onPressed: state.isLoading ? null : _downloadPdf,
          ),
        ],
      ),
      body: Builder(
        builder: (_) {
          // =====================
          // LOADING
          // =====================
          if (state.isLoading && state.recap == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // =====================
          // ERROR
          // =====================
          if (state.error != null) {
            return AppErrorWidget(
              message: state.error!,
              onRetry: () => ref.read(gradeProvider.notifier).loadRecap(),
            );
          }

          final recap = state.recap;

          // =====================
          // NO DATA
          // =====================
          if (recap == null || recap.subjects.isEmpty) {
            return EmptyStateWidget(
              title: 'Belum ada data nilai',
              subtitle:
                  'Nilai akan muncul setelah kamu mengerjakan tugas atau kuis',
              icon: Icons.assessment_outlined,
              actionLabel: 'Refresh',
              onAction: () => ref.read(gradeProvider.notifier).loadRecap(),
            );
          }

          // =====================
          // CONTENT
          // =====================
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(gradeProvider.notifier).loadRecap();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // =====================
                // INFO SISWA
                // =====================
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recap.student.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('NIS : ${recap.student.nis}'),
                        Text('Kelas : ${recap.student.kelas}'),
                      ],
                    ),
                  ),
                ),

                // =====================
                // ACTIONS PDF
                // =====================
                if (state.downloadedPdfPath != null) ...[
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'PDF tersimpan di folder Download',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Buka PDF'),
                              onPressed: () {
                                OpenFilex.open(state.downloadedPdfPath!);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // =====================
                // LIST MAPEL
                // =====================
                ...recap.subjects.map(
                  (subject) => SubjectSection(subject: subject),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
