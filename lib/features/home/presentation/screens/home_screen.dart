import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Dashboard
import '../../data/models/dashboard_model.dart';
import '../../data/models/dashboard_meeting_model.dart';
import '../../data/models/dashboard_pending_task_model.dart';
import '../providers/home_provider.dart';

// Other features
import '../../../auth/data/models/student_model.dart';
import '../../../course/presentation/screens/course_screen.dart';
import '../../../quiz/presentation/screens/lessons_quiz_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../online_class/presentation/screens/online_class_screen.dart';
import '../../../online_class/presentation/screens/jitsi_helper.dart';
import '../../../laporan_harian/presentation/screens/laporan_harian_screen.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../course/domain/providers/course_tab_provider.dart';
import '../../../grades/presentation/screens/recap_grade_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  Timer? _dashboardTimer;

  List<Widget> get _tabs => [
        _DashboardContent(onNavigate: _goToTab),
        const CourseScreen(),
        const OnlineClassScreen(),
        const LessonsQuizScreen(),
        const ProfileScreen(),
      ];

  @override
  void initState() {
    super.initState();
    _dashboardTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (_selectedIndex == 0) {
          ref.invalidate(dashboardDataProvider);
        }
      },
    );
  }

  @override
  void dispose() {
    _dashboardTimer?.cancel();
    super.dispose();
  }

  void _goToTab(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    if (index == 0) ref.invalidate(dashboardDataProvider);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(courseTabProvider, (prev, next) {
      setState(() {
        _selectedIndex = 1;
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(_selectedIndex)),
        centerTitle: true,
      ),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _goToTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Materi'),
          BottomNavigationBarItem(
              icon: Icon(Icons.video_camera_front), label: 'Online'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Quiz'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  String _getTitle(int index) {
    return const [
      'Dashboard',
      'Materi & Tugas',
      'Online Class',
      'Quiz',
      'Profil'
    ][index];
  }
}

// ==============================================================
// DASHBOARD CONTENT
// ==============================================================

class _DashboardContent extends ConsumerWidget {
  final void Function(int index) onNavigate;
  const _DashboardContent({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardDataProvider);

    return dashboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(dashboardDataProvider),
      ),
      data: (data) {
        final now = DateTime.now();

        // Tugas belum dikerjakan & BELUM lewat deadline
        final pending = data.pendingTasks.where((task) {
          return task.dueDate.isAfter(now);
        }).toList();

        // Urgent tasks (< 24 jam)
        final urgentTasks = pending.where((task) {
          final diff = task.dueDate.difference(now);
          return diff.inHours < 24;
        }).toList();

        final todayMeetings =
            data.meetingsToday.where((m) => m.isUpcoming || m.isLive).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardDataProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProfileHeader(student: data.student),
              const SizedBox(height: 24),
              const SectionTitle('Ringkasan Akademik'),
              _StatsGrid(stats: data.stats),
              const SizedBox(height: 28),
              if (urgentTasks.isNotEmpty)
                _UrgentBanner(urgentTasks: urgentTasks),
              if (urgentTasks.isNotEmpty) const SizedBox(height: 20),
              _AssignmentsPreview(tasks: pending, onNavigate: onNavigate),
              const SizedBox(height: 28),
              SectionTitle(
                  '🎥 Kelas Online Hari Ini (${todayMeetings.length})'),
              _MeetingsList(todayMeetings),
              const SizedBox(height: 28),
              const SectionTitle('Akses Cepat'),
              _QuickMenu(onNavigate: onNavigate),
            ],
          ),
        );
      },
    );
  }
}

// ==============================================================
// PROFILE HEADER
// ==============================================================

class _ProfileHeader extends StatelessWidget {
  final StudentModel student;
  const _ProfileHeader({required this.student});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.blue.shade800, Colors.purple.shade800]
              : [Colors.blue.shade400, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Halo,',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  student.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================
// STATS
// ==============================================================

class _StatsGrid extends StatelessWidget {
  final Stats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _stat('Total Tugas', stats.totalTasks, Icons.assignment_rounded,
            [Colors.blue.shade400, Colors.blue.shade600]),
        _stat('Total Materi', stats.totalMaterials, Icons.menu_book_rounded,
            [Colors.teal.shade400, Colors.teal.shade600]),
        _stat('Total Quiz', stats.totalExercises, Icons.quiz_rounded,
            [Colors.purple.shade400, Colors.purple.shade600]),
        _stat('Laporan Harian', stats.reportCount, Icons.event_note_rounded,
            [Colors.orange.shade400, Colors.orange.shade600]),
      ],
    );
  }

  Widget _stat(String title, dynamic value, IconData icon, List<Color> colors) {
    final display =
        value is double ? value.toStringAsFixed(0) : value.toString();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: colors[0], size: 24),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  display,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors[0],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================
// URGENT TASK BANNER
// ==============================================================

class _UrgentBanner extends StatelessWidget {
  final List<PendingTaskModel> urgentTasks;
  const _UrgentBanner({required this.urgentTasks});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark
          ? Colors.red.shade900.withValues(alpha: 0.3)
          : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red.shade700, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Ada ${urgentTasks.length} tugas akan segera jatuh tempo!",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.red.shade200 : Colors.red.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================
// PENDING ASSIGNMENTS PREVIEW
// ==============================================================

class _AssignmentsPreview extends ConsumerWidget {
  final List<PendingTaskModel> tasks;
  final void Function(int index) onNavigate;

  const _AssignmentsPreview({
    required this.tasks,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    final preview = tasks.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle("Tugas Belum Dikerjakan (${tasks.length})"),
        const SizedBox(height: 8),
        ...preview.map((task) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            color: isDark ? null : Colors.orange.shade50,
            child: ListTile(
              leading: Icon(Icons.assignment_rounded,
                  color: Colors.orange.shade700, size: 28),
              title: Text(
                task.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                "⏰ ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}",
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
              ),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/assignment/detail',
                  arguments: task.id,
                );
              },
            ),
          );
        }),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              ref.read(courseTabProvider.notifier).state = 1;
              onNavigate(1);
            },
            icon: const Icon(Icons.list_alt_rounded),
            label: const Text("Lihat Semua"),
          ),
        ),
      ],
    );
  }
}

// ==============================================================
// MEETINGS LIST
// ==============================================================

class _MeetingsList extends StatelessWidget {
  final List<DashboardMeetingModel> meetings;
  const _MeetingsList(this.meetings);

  String _countdown(DateTime startTime) {
    final diff = startTime.difference(DateTime.now());
    if (diff.isNegative) return 'Mulai';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return h > 0 ? '$h jam $m mnt' : '$m mnt lagi';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (meetings.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.event_busy_rounded,
                  color: Colors.grey.shade400, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tidak ada kelas online hari ini',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: meetings.map((m) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: m.isLive
              ? (isDark ? null : Colors.green.shade50)
              : (isDark ? null : Colors.blue.shade50),
          child: ListTile(
            leading: Icon(
              Icons.video_camera_front_rounded,
              color: m.isLive ? Colors.green.shade700 : Colors.blue.shade700,
              size: 28,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    m.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                m.isLive
                    ? InkWell(
                        onTap: () async {
                          await JitsiHelper.joinMeeting(
                            room: m.meetingCode,
                            displayName: 'Siswa',
                          );
                        },
                        child: const Chip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Colors.white, size: 8),
                              SizedBox(width: 4),
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.green,
                        ),
                      )
                    : Chip(
                        label: Text(
                          _countdown(m.startTime),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ],
            ),
            subtitle: Text(
              '🕐 ${m.startTime.hour.toString().padLeft(2, '0')}:${m.startTime.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ==============================================================
// QUICK MENU
// ==============================================================

class _QuickMenu extends StatelessWidget {
  final void Function(int index) onNavigate;
  const _QuickMenu({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        _item(
            'Materi',
            Icons.menu_book_rounded,
            [Colors.blue.shade400, Colors.blue.shade600],
            () => onNavigate(1),
            isDark),
        _item(
            'Tugas',
            Icons.edit_note_rounded,
            [Colors.orange.shade400, Colors.orange.shade600],
            () => onNavigate(1),
            isDark),
        _item(
            'Online',
            Icons.video_camera_front_rounded,
            [Colors.green.shade400, Colors.green.shade600],
            () => onNavigate(2),
            isDark),
        _item(
            'Quiz',
            Icons.quiz_rounded,
            [Colors.blue.shade400, Colors.blue.shade600],
            () => onNavigate(3),
            isDark),
        _item('Nilai', Icons.assessment_rounded,
            [Colors.orange.shade400, Colors.orange.shade600], () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RecapGradeScreen(),
            ),
          );
        }, isDark),
        _item('Laporan', Icons.event_note_rounded,
            [Colors.green.shade400, Colors.green.shade600], () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LaporanHarianScreen()),
          );
        }, isDark),
      ],
    );
  }

  Widget _item(String label, IconData icon, List<Color> colors,
      VoidCallback onTap, bool isDark) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colors[0], size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================
// ERROR VIEW
// ==============================================================

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
