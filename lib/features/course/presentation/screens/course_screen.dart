import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/providers/course_providers.dart';
import '../../data/models/assignment_model.dart';
import '../../data/models/course_material_model.dart';
import 'material_detail_screen.dart';
import 'assignment_detail_screen.dart';
import '../../domain/providers/course_tab_provider.dart';

// ==================================
// COURSE SCREEN (MATERI & TUGAS)
// ==================================
class CourseScreen extends ConsumerStatefulWidget {
  const CourseScreen({super.key});

  @override
  ConsumerState<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends ConsumerState<CourseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _didListen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: ref.read(courseTabProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    /// 💡 Setup listener here — SAFE & recommended by Riverpod Team
    if (!_didListen) {
      _didListen = true;
      ref.listen<int>(courseTabProvider, (prev, next) {
        if (!mounted) return;
        if (_tabController.index != next) {
          _tabController.animateTo(next);
        }
      });
    }

    return Scaffold(
      body: Column(
        children: [
          Material(
            color: Colors.white,
            elevation: 1,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blueAccent,
              onTap: (i) {
                ref.read(courseTabProvider.notifier).state = i;
              },
              tabs: const [
                Tab(text: 'Materi', icon: Icon(Icons.folder_open)),
                Tab(text: 'Tugas', icon: Icon(Icons.assignment)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _MateriListView(),
                _TugasListView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}


// ==========================================================
// MATERI LIST
// ==========================================================
class _MateriListView extends ConsumerWidget {
  const _MateriListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMaterials = ref.watch(courseMaterialsProvider);

    return asyncMaterials.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text('Gagal memuat materi\n${e.toString()}')),
      data: (materials) {
        if (materials.isEmpty) {
          return const Center(
            child: Text('Tidak ada materi tersedia'),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(courseMaterialsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: materials.length,
            itemBuilder: (context, index) {
              final CourseMaterialModel item = materials[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(
                    Icons.insert_drive_file,
                    color: Colors.blue,
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    item.subjectName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
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
// TUGAS LIST
// ==========================================================
// ==========================================================
// TUGAS LIST (AUTO REFRESH ACTIVE)
// ==========================================================
class _TugasListView extends ConsumerWidget {
  const _TugasListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAssignments = ref.watch(courseAssignmentsProvider);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return asyncAssignments.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text('Gagal memuat tugas\n${e.toString()}')),
      data: (tugasList) {
        if (tugasList.isEmpty) {
          return const Center(
            child: Text('Tidak ada tugas'),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(courseAssignmentsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tugasList.length,
            itemBuilder: (context, index) {
              final AssignmentModel item = tugasList[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.statusColor,
                    child: const Icon(Icons.assignment, color: Colors.white),
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Deadline: ${dateFormat.format(item.dueDate)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    item.status,
                    style: TextStyle(
                      color: item.statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AssignmentDetailScreen(
                          assignmentId: item.id,
                        ),
                      ),
                    ).then((_) {
                      // 🔄 Auto refresh after returning from detail screen
                      ref.invalidate(courseAssignmentsProvider);
                    });
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
