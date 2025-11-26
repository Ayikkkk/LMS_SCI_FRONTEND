import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/providers/course_providers.dart';
import '../../domain/models/assignment_model.dart';
import '../../domain/models/course_material_model.dart';
import '../screens/material_detail_screen.dart';
import '../screens/assignment_detail_screen.dart'; // 💡 IMPORT BARU untuk Detail Tugas

// ==========================================================
// HALAMAN COURSE (MATERI & TUGAS)
// ==========================================================
class CourseScreen extends StatelessWidget {
  const CourseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blueAccent,
            tabs: [
              Tab(text: 'Materi (Modul)', icon: Icon(Icons.folder_open)),
              Tab(text: 'Tugas (Assignment)', icon: Icon(Icons.assignment)),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _MateriListView(),
                _TugasListView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// WIDGET: DAFTAR MATERI
// ==========================================================
class _MateriListView extends ConsumerWidget {
  const _MateriListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMaterials = ref.watch(courseMaterialsProvider);

    return asyncMaterials.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Gagal memuat materi: ${error.toString()}')),
      data: (materials) {
        if (materials.isEmpty) {
          return const Center(
            child: Text('Tidak ada materi yang tersedia untuk saat ini.'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(courseMaterialsProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: materials.length,
            itemBuilder: (context, index) {
              final CourseMaterialModel item = materials[index];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file,
                      color: Colors.blue),
                  title: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${item.subjectName} • ${item.description ?? 'Klik untuk melihat detail'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            MaterialDetailScreen(materialId: item.id),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ==========================================================
// WIDGET: DAFTAR TUGAS
// ==========================================================
class _TugasListView extends ConsumerWidget {
  const _TugasListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAssignments = ref.watch(courseAssignmentsProvider);

    return asyncAssignments.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Gagal memuat tugas: ${error.toString()}')),
      data: (tugasList) {
        if (tugasList.isEmpty) {
          return const Center(
            child: Text('Tidak ada tugas yang harus dikerjakan.'),
          );
        }

        final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

        return RefreshIndicator(
          onRefresh: () => ref.refresh(courseAssignmentsProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tugasList.length,
            itemBuilder: (context, index) {
              final AssignmentModel item = tugasList[index];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.statusColor,
                    child: const Icon(Icons.assignment, color: Colors.white),
                  ),
                  title: Text(item.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.subjectName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description ?? 'Tidak ada deskripsi',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tenggat: ${dateFormat.format(item.dueDate)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        color: item.statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // 💡 PERBAIKAN: Mengganti SnackBar dengan navigasi ke AssignmentDetailScreen
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            AssignmentDetailScreen(assignmentId: item.id),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}