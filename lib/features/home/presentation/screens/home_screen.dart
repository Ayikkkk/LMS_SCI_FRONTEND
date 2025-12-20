// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import komponen dari fitur Home
import '../../data/models/dashboard_model.dart';
import '../providers/home_provider.dart';

// Import komponen dari fitur lain
import '../../../auth/data/models/student_model.dart';
import '../../../course/presentation/screens/course_screen.dart';
import '../../../quiz/presentation/screens/lessons_quiz_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();

    // INIT TAB WIDGETS
    _widgetOptions = <Widget>[
      const _DashboardContent(),
      const CourseScreen(),
      const LessonsQuizScreen(),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Re-fetch otomatis saat tab Home dibuka
    if (index == 0) {
      ref.invalidate(dashboardDataProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle(_selectedIndex)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Course"),
          BottomNavigationBarItem(icon: Icon(Icons.question_answer), label: "Quiz"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard Siswa';
      case 1:
        return 'Materi & Pembelajaran';
      case 2:
        return 'Tes & Evaluasi';
      case 3:
        return 'Profil Pengguna';
      default:
        return 'Aplikasi Siswa';
    }
  }
}

// ==========================================================================
// DASHBOARD CONTENT
// ==========================================================================

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardDataAsync = ref.watch(dashboardDataProvider);

    return dashboardDataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Gagal memuat data: $err'),
            ElevatedButton(
              onPressed: () => ref.invalidate(dashboardDataProvider),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
      data: (data) {
        final StudentModel student = data.student;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(context, student),
              const Divider(height: 30),

              // RINGKASAN
              Text('Ringkasan Akademik', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 15),
              _buildStatsGrid(context, data.stats),

              const SizedBox(height: 30),

              // MEETING
              Text('Kelas Online Hari Ini (${data.meetingsToday.length})',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 15),
              _buildMeetingsList(data.meetingsToday),

              const SizedBox(height: 30),

              // MODULE
              Text('Akses Cepat Modul', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 15),
              _buildModuleTiles(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, StudentModel student) {
    // gunakan nama field yang benar: classroomId
    final className = student.className ?? (student.classroomId?.toString()) ?? 'Tidak diketahui';

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
            Text('Halo, ${student.name}!',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            Text('Kelas: ${student.className ?? 'Tidak diketahui'}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.grey[700])),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, Stats stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _statCard(context, 'Total Tugas', stats.totalTasks, Icons.assignment, Colors.orange),
        _statCard(context, 'Total Quiz', stats.totalExercises, Icons.quiz, Colors.purple),
        _statCard(context, 'Rata-rata Tugas', stats.averageTaskScore, Icons.score, Colors.green),
        _statCard(context, 'Rata-rata Quiz', stats.averageExerciseScore, Icons.star, Colors.blue),
        _statCard(context, 'Laporan Terkirim', stats.reportCount, Icons.event_note, Colors.redAccent),
      ],
    );
  }

  Widget _statCard(BuildContext context, String title, dynamic value, IconData icon, Color color) {
    final displayValue = (value is double) ? value.toStringAsFixed(2) : value.toString();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            Text(displayValue,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingsList(List<OnlineMeetingModel> meetings) {
    if (meetings.isEmpty) {
      return const Center(
        child: Text('Tidak ada kelas online hari ini.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: meetings.map((meeting) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: const Icon(Icons.video_call, color: Colors.red),
            title: Text(meeting.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                'Pukul ${meeting.startTime.substring(11, 16)} - ${meeting.endTime.substring(11, 16)} (${meeting.platform})'),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModuleTiles(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _moduleItem(context, 'Materi', Icons.folder_open, Colors.blue),
        _moduleItem(context, 'Tugas', Icons.check_circle_outline, Colors.orange),
        _moduleItem(context, 'Quiz', Icons.edit_note, Colors.green, onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LessonsQuizScreen()),
          );
        }),
        _moduleItem(context, 'Laporan', Icons.event_note, Colors.red),
        _moduleItem(context, 'Nilai', Icons.bar_chart, Colors.purple),
        _moduleItem(context, 'Pengaturan', Icons.settings, Colors.grey),
      ],
    );
  }

  Widget _moduleItem(BuildContext context, String label, IconData icon, Color color, {VoidCallback? onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap ??
            () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('$label belum diimplementasikan.')));
            },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 35, color: color),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
