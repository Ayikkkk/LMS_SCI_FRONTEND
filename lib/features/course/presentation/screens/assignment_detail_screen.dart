import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_html/flutter_html.dart';

import '../screens/submit_task_screen.dart';
import '../../presentation/screens/material_detail_screen.dart'
    show ExternalLinkWidget, AttachmentFileWidget, VideoEmbedWidget;

import '../../domain/providers/course_providers.dart';
import '../../domain/models/assignment_model.dart';

class AssignmentDetailScreen extends ConsumerWidget {
  final int assignmentId;

  const AssignmentDetailScreen({super.key, required this.assignmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAssignment =
        ref.watch(assignmentDetailProvider(assignmentId));

    Intl.defaultLocale = 'id_ID';

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Tugas')),
      // Menerapkan RefreshIndicator untuk pull-to-refresh
      body: RefreshIndicator(
        onRefresh: () async {
          // Memaksa provider mengambil data ulang dari server
          return ref.refresh(assignmentDetailProvider(assignmentId));
        },
        child: asyncAssignment.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Center(child: Text('Gagal memuat detail tugas: $e')),
            ),
          ),
          data: (assignment) => _buildContent(context, ref, assignment),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AssignmentModel assignment,
  ) {
    final bool isSubmitted =
        assignment.status.toLowerCase().contains('sudah');

    final bool isOverdue =
        DateTime.now().isAfter(assignment.dueDate) && !isSubmitted;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= HEADER =================
          Text(
            assignment.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            assignment.subjectName,
            style: TextStyle(color: Colors.grey.shade600),
          ),

          const Divider(height: 32),

          // ================= INFO =================
          _infoRow(
            icon: Icons.access_time,
            label: 'Tenggat:',
            value: DateFormat(
              'EEEE, dd MMMM yyyy HH:mm',
            ).format(assignment.dueDate),
            color: Colors.redAccent,
          ),
          const SizedBox(height: 6),
          _infoRow(
            icon: Icons.check_circle,
            label: 'Status:',
            value: assignment.status,
            color: assignment.statusColor,
            bold: true,
          ),
          if (isSubmitted) ...[
            const SizedBox(height: 6),
            _infoRow(
              icon: Icons.grade,
              label: 'Nilai:',
              value: assignment.point,
              color: Colors.blue.shade700,
              bold: true,
            ),
          ],

          const SizedBox(height: 24),

          // Tampilan Nilai Besar (Card) jika sudah dinilai
          if (isSubmitted && assignment.point != "-") ...[
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hasil Penilaian",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      Text("Tugas telah diverifikasi",
                          style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    ],
                  ),
                  Text(
                    assignment.point,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ================= DESKRIPSI =================
          const Text(
            'Deskripsi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          assignment.description != null &&
                  assignment.description!.isNotEmpty
              ? Html(data: assignment.description!)
              : const Text(
                  'Tidak ada deskripsi.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),

          // ================= LINK MATERI =================
          if (assignment.link?.isNotEmpty == true) ...[
            const SizedBox(height: 24),
            const Text(
              'Link Materi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ExternalLinkWidget(
              url: assignment.link!,
              label: 'Buka Tautan',
            ),
          ],

          // ================= FILE LAMPIRAN =================
          if (assignment.attachment?.isNotEmpty == true) ...[
            const SizedBox(height: 24),
            const SizedBox(height: 8),
            AttachmentFileWidget(
              path: assignment.attachment!,
              fileType: assignment.attachment!
                  .split('.')
                  .last
                  .toLowerCase(),
            ),
          ],

          // ================= KONTEN MATERI =================
          if (assignment.embed?.isNotEmpty == true) ...[
            const SizedBox(height: 24),
            const Text(
              'Konten Materi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            VideoEmbedWidget(embedCode: assignment.embed!),
          ],

          const SizedBox(height: 32),

          // ================= ACTION BUTTON =================
          Center(
            child: ElevatedButton.icon(
              onPressed: (isSubmitted || isOverdue)
                  ? null
                  : () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SubmitTaskScreen(
                            assignmentId: assignment.id,
                            assignmentTitle: assignment.title,
                            isSubmitted: isSubmitted,
                          ),
                        ),
                      );

                      if (result == true) {
                        ref.invalidate(
                            assignmentDetailProvider(assignment.id));

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tugas berhasil dikirim.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
              icon: Icon(
                isSubmitted
                    ? Icons.check_circle_outline
                    : isOverdue
                        ? Icons.warning
                        : Icons.upload_file,
              ),
              label: Text(
                isSubmitted
                    ? (assignment.point != "-" ? 'Tugas Selesai Dinilai' : 'Menunggu Penilaian')
                    : isOverdue
                        ? 'Tenggat Terlewat'
                        : 'Unggah Tugas',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 50), // Ruang tambahan untuk scroll tarik bawah
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color color = Colors.black,
    bool bold = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}