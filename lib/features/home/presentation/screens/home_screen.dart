import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Home feature
import '../../data/models/dashboard_model.dart';
import '../providers/home_provider.dart';
import '../../data/models/dashboard_meeting_model.dart';

// Other features
import '../../../auth/data/models/student_model.dart';
import '../../../course/presentation/screens/course_screen.dart';
import '../../../quiz/presentation/screens/lessons_quiz_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../online_class/presentation/screens/online_class_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _tabs = const [
    _DashboardContent(),
    CourseScreen(),
    OnlineClassScreen(),
    LessonsQuizScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    // refresh dashboard when back to Home
    if (index == 0) {
      ref.invalidate(dashboardDataProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(_selectedIndex)),
        backgroundColor: Colors.blueAccent,
      ),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Course'),
          BottomNavigationBarItem(
              icon: Icon(Icons.video_camera_front), label: 'Online Class'),
          BottomNavigationBarItem(
              icon: Icon(Icons.question_answer), label: 'Quiz'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard Siswa';
      case 1:
        return 'Materi & Pembelajaran';
      case 2:
        return 'Kelas Online';
      case 3:
        return 'Tes & Evaluasi';
      case 4:
        return 'Profil Pengguna';
      default:
        return 'Aplikasi Siswa';
    }
  }
}

// ======================================================================
// DASHBOARD CONTENT
// ======================================================================

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDashboard = ref.watch(dashboardDataProvider);

    return asyncDashboard.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Gagal memuat data:\n$e',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(dashboardDataProvider),
              child: const Text('Coba Lagi'),
            )
          ],
        ),
      ),
      data: (data) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _profileHeader(context, data.student),
              const Divider(height: 30),

              Text(
                'Ringkasan Akademik',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 15),
              _statsGrid(context, data.stats),

              const SizedBox(height: 30),
              Text(
                'Kelas Online Hari Ini (${data.meetingsToday.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 15),
              _meetingsList(data.meetingsToday),

              const SizedBox(height: 30),
              Text(
                'Akses Cepat Modul',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 15),
              _moduleTiles(context),
            ],
          ),
        );
      },
    );
  }

  // ================= HEADER =================

  Widget _profileHeader(BuildContext context, StudentModel student) {
    final className =
        student.className ?? student.classroomId?.toString() ?? '-';

    return Row(
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundColor: Colors.blueGrey,
          child: Icon(Icons.person, color: Colors.white, size: 30),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, ${student.name}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
            ),
            Text(
              'Kelas: $className',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ],
    );
  }

  // ================= STATS =================

  Widget _statsGrid(BuildContext context, Stats stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _statCard(context, 'Total Tugas', stats.totalTasks,
            Icons.assignment, Colors.orange),
        _statCard(context, 'Total Quiz', stats.totalExercises,
            Icons.quiz, Colors.purple),
        _statCard(context, 'Rata-rata Tugas',
            stats.averageTaskScore, Icons.score, Colors.green),
        _statCard(context, 'Rata-rata Quiz',
            stats.averageExerciseScore, Icons.star, Colors.blue),
        _statCard(context, 'Laporan',
            stats.reportCount, Icons.event_note, Colors.redAccent),
      ],
    );
  }

  Widget _statCard(BuildContext context, String title, dynamic value,
      IconData icon, Color color) {
    final display =
        value is double ? value.toStringAsFixed(2) : value.toString();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const Spacer(),
            Text(title, style: const TextStyle(color: Colors.grey)),
            Text(
              display,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= MEETINGS =================

  Widget _meetingsList(List<DashboardMeetingModel> meetings) {
    if (meetings.isEmpty) {
      return const Text(
        'Tidak ada kelas online hari ini.',
        style: TextStyle(color: Colors.grey),
      );
    }

    String formatTime(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    return Column(
      children: meetings.map((m) {
        final timeRange = m.endTime != null
            ? '${formatTime(m.startTime)} - ${formatTime(m.endTime!)}'
            : formatTime(m.startTime);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const Icon(Icons.video_call, color: Colors.red),
            title: Text(
              m.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Pukul $timeRange (${m.platform})',
            ),
          ),
        );
      }).toList(),
    );
  }

  // ================= MODULES =================

  Widget _moduleTiles(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _module(context, 'Materi', Icons.folder_open, Colors.blue),
        _module(context, 'Tugas', Icons.check_circle_outline, Colors.orange),
        _module(context, 'Quiz', Icons.edit_note, Colors.green,
            onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LessonsQuizScreen()),
                )),
        _module(context, 'Laporan', Icons.event_note, Colors.red),
        _module(context, 'Nilai', Icons.bar_chart, Colors.purple),
        _module(context, 'Pengaturan', Icons.settings, Colors.grey),
      ],
    );
  }

  Widget _module(BuildContext context, String label,
      IconData icon, Color color,
      {VoidCallback? onTap}) {
    return Card(
      child: InkWell(
        onTap: onTap ??
            () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$label belum tersedia')),
                ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
