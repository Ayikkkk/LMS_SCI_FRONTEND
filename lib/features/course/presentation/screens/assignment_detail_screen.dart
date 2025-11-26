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
    final asyncAssignmentDetail =
        ref.watch(assignmentDetailProvider(assignmentId));

    Intl.defaultLocale = 'id';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tugas'),
        backgroundColor: Colors.blueAccent,
      ),
      body: asyncAssignmentDetail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Gagal memuat detail tugas: ${error.toString()}'),
          ),
        ),
        data: (assignment) => _buildDetailContent(context, ref, assignment),
      ),
    );
  }

  Widget _buildDetailContent(
      BuildContext context, WidgetRef ref, AssignmentModel assignment) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(assignment),
          const Divider(height: 30, thickness: 1),

          // Judul
          Text(
            assignment.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),

          // Tanggal & Status
          _buildInfoRow(
            icon: Icons.access_time_filled,
            label: 'Tenggat Waktu:',
            value: DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID')
                .format(assignment.dueDate),
            color: Colors.redAccent.shade400,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.check_circle,
            label: 'Status Tugas:',
            value: assignment.status,
            color: assignment.statusColor,
            isBold: true,
          ),

          const SizedBox(height: 20),

          // ======================
          // DESKRIPSI
          // ======================
          const Text(
            'Deskripsi:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),
          assignment.description != null && assignment.description!.isNotEmpty
              ? Html(data: assignment.description!)
              : const Text(
                  'Tidak ada deskripsi rinci yang tersedia.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),

          const SizedBox(height: 20),

          // ======================
          // 🔗 LINK EKSTERNAL
          // ======================
          if (assignment.link != null && assignment.link!.isNotEmpty) ...[
            const Divider(),
            ExternalLinkWidget(
              url: assignment.link!,
              label: 'Buka Tautan Eksternal',
            ),
            const SizedBox(height: 20),
          ],

          // ======================
          // 📎 FILE ATTACHMENT (DARI GURU)
          // ======================
          if (assignment.attachment != null &&
              assignment.attachment!.isNotEmpty) ...[
            const Divider(),

            // FIX → convert nama file menjadi URL lengkap
            AttachmentFileWidget(
              path:
                  "http://127.0.0.1:8000/storage/posts/${assignment.attachment!}",
              fileType: assignment.attachment!.split('.').last,
            ),

            const SizedBox(height: 20),
          ],

          // ======================
          // 🎥 EMBED VIDEO
          // ======================
          if (assignment.embed != null && assignment.embed!.isNotEmpty) ...[
            const Divider(),
            VideoEmbedWidget(embedCode: assignment.embed!),
            const SizedBox(height: 20),
          ],

          // ======================
          // 📤 FILE TUGAS YANG DIKIRIM SISWA
          // ======================
          if (assignment.studentAttachment != null)
            _buildFileSection(context, assignment.studentAttachment!),

          const SizedBox(height: 30),

          // Tombol Aksi
          _buildActionButton(context, ref, assignment),
        ],
      ),
    );
  }

  Widget _buildHeader(AssignmentModel assignment) {
    return Row(
      children: [
        const Icon(Icons.class_, color: Colors.blueAccent, size: 28),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              assignment.subjectName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blueAccent.shade700,
              ),
            ),
            Text(
              'Mapel ID: ${assignment.mapelId}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color color = Colors.black,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileSection(BuildContext context, String fileName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'File Tugas yang Dikirim:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 3,
          color: Colors.grey.shade100,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
            title: Text(fileName),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Fitur download $fileName belum diimplementasi.')),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      BuildContext context, WidgetRef ref, AssignmentModel assignment) {
    final bool isSubmitted =
        assignment.status.toLowerCase() == 'sudah mengumpulkan' ||
            assignment.status.toLowerCase() == 'sudah dinilai';

    final bool isOverdue =
        DateTime.now().isAfter(assignment.dueDate) && !isSubmitted;

    return Center(
      child: ElevatedButton.icon(
        onPressed: (isSubmitted || isOverdue)
            ? null
            : () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SubmitTaskScreen(
                      assignmentId: assignment.id,
                      assignmentTitle: assignment.title,
                      isSubmitted: assignment.status.toLowerCase() ==
                              "sudah mengumpulkan" ||
                          assignment.status.toLowerCase() == "sudah dinilai",
                    ),
                  ),
                );

                if (result == true) {
                  ref.invalidate(assignmentDetailProvider(assignment.id));

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          '✅ Tugas berhasil dikirim dan status diperbarui.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
        icon: Icon(
          isSubmitted
              ? Icons.check_circle_outline
              : (isOverdue ? Icons.warning : Icons.upload_file),
        ),
        label: Text(
          isSubmitted
              ? 'Sudah Mengumpulkan'
              : (isOverdue ? 'Tenggat Terlewat' : 'Unggah Tugas Sekarang'),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSubmitted
              ? Colors.green
              : (isOverdue ? Colors.grey : Colors.blueAccent),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 5,
        ),
      ),
    );
  }
}
