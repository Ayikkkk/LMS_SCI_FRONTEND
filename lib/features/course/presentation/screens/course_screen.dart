import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/constants/error_messages.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  bool _didListen = false;
  Timer? _refreshTimer;

  static const Duration _pollInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: ref.read(courseTabProvider),
    );
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_pollInterval, (_) => _refresh());
  }

  void _refresh() {
    if (!mounted) return;
    ref.invalidate(courseMaterialsProvider);
    ref.invalidate(courseAssignmentsProvider);
  }

  // Refresh saat app kembali ke foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
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
      error: (e, _) => AppErrorWidget(
        message: ErrorMessages.fromException(e),
        onRetry: () => ref.invalidate(courseMaterialsProvider),
      ),
      data: (materials) {
        if (materials.isEmpty) {
          return EmptyStateWidget(
            title: 'Belum ada materi',
            subtitle: 'Materi akan muncul di sini saat guru menambahkannya',
            icon: Icons.folder_open_rounded,
            actionLabel: 'Refresh',
            onAction: () => ref.invalidate(courseMaterialsProvider),
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

class _TugasListView extends ConsumerWidget {
  const _TugasListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAssignments = ref.watch(courseAssignmentsProvider);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return asyncAssignments.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorWidget(
        message: ErrorMessages.fromException(e),
        onRetry: () => ref.invalidate(courseAssignmentsProvider),
      ),
      data: (tugasList) {
        if (tugasList.isEmpty) {
          return EmptyStateWidget(
            title: 'Belum ada tugas',
            subtitle: 'Tugas akan muncul di sini saat guru menambahkannya',
            icon: Icons.assignment_outlined,
            actionLabel: 'Refresh',
            onAction: () => ref.invalidate(courseAssignmentsProvider),
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
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama mapel kecil di atas judul
                      Text(
                        item.subjectName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.dueDate != null
                          ? 'Deadline: ${dateFormat.format(item.dueDate!)}'
                          : 'Tanpa batas waktu',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  trailing: Text(
                    item.status,
                    style: TextStyle(
                      color: item.statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
