import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/providers/grade_provider.dart';
import '../widgets/subject_section.dart';
import '../../../../core/utils/download_exporter.dart';
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mengunduh rekap nilai...')),
    );

    final File? file = await notifier.downloadPdf();

    if (!mounted) return;

    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengunduh PDF')),
      );
    }
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(gradeProvider.notifier).loadRecap();
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final recap = state.recap;

          // =====================
          // NO DATA
          // =====================
          if (recap == null || recap.subjects.isEmpty) {
            return const Center(child: Text('Belum ada data nilai'));
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
                if (state.downloadedPdf != null) ...[
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rekap Nilai (PDF)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.picture_as_pdf),
                                  label: const Text('Buka PDF'),
                                  onPressed: () {
                                    OpenFilex.open(
                                      state.downloadedPdf!.path,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.folder_copy),
                                  label:
                                      const Text('Salin ke Download'),
                                  onPressed: () async {
                                    final success =
                                        await DownloadExporter.copyToDownload(
                                      state.downloadedPdf!,
                                    );

                                    if (!mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? 'PDF berhasil disalin ke Download'
                                              : 'Gagal menyalin PDF',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
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
