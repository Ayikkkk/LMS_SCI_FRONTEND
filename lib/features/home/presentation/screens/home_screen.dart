import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Dashboard
import '../../data/models/dashboard_model.dart';
import '../../data/models/dashboard_meeting_model.dart';
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

    /// 🔁 Auto refresh dashboard tiap 30 detik
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

    if (index == 0) {
      ref.invalidate(dashboardDataProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
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
      'Materi',
      'Online Class',
      'Quiz',
      'Profil',
    ][index];
  }
}

// ======================================================================
// DASHBOARD CONTENT
// ======================================================================

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
        final todayMeetings = data.meetingsToday
            .where((m) => m.isUpcoming || m.isLive)
            .toList();

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardDataProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProfileHeader(student: data.student),
              const SizedBox(height: 24),

              const SectionTitle('Ringkasan Akademik'),
              _StatsGrid(stats: data.stats),

              const SizedBox(height: 28),
              SectionTitle(
                  'Kelas Online Hari Ini (${todayMeetings.length})'),
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

// ======================================================================
// HEADER
// ======================================================================

class _ProfileHeader extends StatelessWidget {
  final StudentModel student;
  const _ProfileHeader({required this.student});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Halo, ${student.name}',
      style: Theme.of(context)
          .textTheme
          .headlineSmall
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

// ======================================================================
// STATS GRID
// ======================================================================

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
      children: [
        _stat('Total Tugas', stats.totalTasks, Icons.assignment, Colors.orange),
        _stat('Total Quiz', stats.totalExercises, Icons.quiz, Colors.purple),
        _stat('Rata-rata Tugas', stats.averageTaskScore, Icons.score,
            Colors.green),
        _stat('Rata-rata Quiz', stats.averageExerciseScore, Icons.star,
            Colors.blue),
      ],
    );
  }

  Widget _stat(
      String title, dynamic value, IconData icon, Color color) {
    final display =
        value is double ? value.toStringAsFixed(2) : value.toString();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(title,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              display,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// MEETINGS LIST (LIVE + COUNTDOWN + JOIN)
// ======================================================================

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
    if (meetings.isEmpty) {
      return const Text(
        'Tidak ada kelas online hari ini',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      children: meetings.map((m) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Icon(Icons.video_call,
                color: m.isLive ? Colors.red : Colors.orange),
            title: Row(
              children: [
                Expanded(
                  child: Text(m.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
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
                          label: Text('LIVE',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 11)),
                          backgroundColor: Colors.red,
                        ),
                      )
                    : Chip(
                        label: Text(_countdown(m.startTime),
                            style: const TextStyle(fontSize: 11)),
                      ),
              ],
            ),
            subtitle: Text(
              'Mulai ${m.startTime.hour.toString().padLeft(2, '0')}:${m.startTime.minute.toString().padLeft(2, '0')}',
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ======================================================================
// QUICK MENU
// ======================================================================

class _QuickMenu extends StatelessWidget {
  final void Function(int index) onNavigate;

  const _QuickMenu({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _item('Materi', Icons.folder_open, Colors.blue, () => onNavigate(1)),
        _item('Tugas', Icons.check_circle_outline, Colors.orange,
            () => onNavigate(1)),
        _item('Online', Icons.video_camera_front, Colors.red,
            () => onNavigate(2)),
        _item('Quiz', Icons.quiz, Colors.green, () => onNavigate(3)),
        _item('Laporan', Icons.event_note, Colors.purple, () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const LaporanHarianScreen()),
          );
        }),
        _item('Profil', Icons.person, Colors.grey, () => onNavigate(4)),
      ],
    );
  }

  Widget _item(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// ERROR VIEW
// ======================================================================

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
