// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import komponen dari fitur Home
import '../../data/models/dashboard_model.dart';
import '../providers/home_provider.dart'; // Pastikan Provider sudah dibuat!

// Import komponen dari fitur lain
// 💡 Ganti path ini sesuai lokasi StudentModel Anda
import '../../../auth/data/models/student_model.dart';
import '../../../course/presentation/screens/course_screen.dart'; // Akan dibuat di bawah
import '../../../quiz/presentation/screens/quiz_screen.dart';       // Akan dibuat di bawah
import '../../../profile/presentation/screens/profile_screen.dart';   // Akan dibuat di bawah


// --- WIDGET UTAMA (CONSUMER STATEFUL) ---
// Diubah dari DashboardScreen menjadi HomeScreen
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
    _widgetOptions = <Widget>[
      // Index 0: HOME (Dashboard Content)
      const _DashboardContent(),
      // Index 1: COURSE
      const CourseScreen(),
      // Index 2: QUIZ
      const QuizScreen(),
      // Index 3: PROFIL
      const ProfileScreen(), 
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Course',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.question_answer),
            label: 'Quiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
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

// --- KONTEN DASHBOARD (Halaman Home/Index 0) ---
// Diubah agar tidak perlu menerima WidgetRef di constructor (bisa diakses di method build)
class _DashboardContent extends ConsumerWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memanggil provider
    final dashboardDataAsync = ref.watch(dashboardDataProvider);

    return dashboardDataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Gagal memuat data: $err'),
            ElevatedButton(
              onPressed: () {
                // Gunakan ref dari parameter build untuk memuat ulang data
                ref.invalidate(dashboardDataProvider);
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
      data: (data) {
        // MENGGANTI StudentInfo dengan StudentModel
        final StudentModel student = data.student;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(context, student),
              const Divider(height: 30),
              Text('Ringkasan Akademik',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 15),
              _buildStatsGrid(context, data.stats),
              const SizedBox(height: 30),
              Text('Kelas Online Hari Ini (${data.meetingsToday.length})',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 15),
              _buildMeetingsList(data.meetingsToday),
              const SizedBox(height: 30),
              Text('Akses Cepat Modul',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 15),
              _buildModuleTiles(context),
            ],
          ),
        );
      },
    );
  }

  // --- Helper Methods (Diperbarui menggunakan StudentModel) ---

  Widget _buildProfileHeader(BuildContext context, StudentModel student) {
    // ⚠️ student.classroomName mungkin null/kosong tergantung implementasi StudentModel
    final className = student.className ?? student.classRoomId?.toString() ?? 'Tidak diketahui';

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
              'Halo, ${student.name}!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            Text(
              'Kelas: $className',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey[700]),
            ),
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
        _buildStatCard(context, 'Total Tugas', stats.totalTasks,
            Icons.assignment, Colors.orange),
        _buildStatCard(context, 'Total Quiz', stats.totalExercises, Icons.quiz,
            Colors.purple),
        _buildStatCard(context, 'Rata-rata Tugas', stats.averageTaskScore,
            Icons.score, Colors.green),
        _buildStatCard(context, 'Rata-rata Quiz', stats.averageExerciseScore,
            Icons.star, Colors.blue),
        _buildStatCard(context, 'Laporan Terkirim', stats.reportCount,
            Icons.event_note, Colors.redAccent),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, dynamic value,
      IconData icon, Color color) {
    String displayValue =
        (value is double) ? value.toStringAsFixed(2) : value.toString();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              displayValue,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingsList(List<OnlineMeetingModel> meetings) {
    if (meetings.isEmpty) {
      return const Center(
          child: Text('Tidak ada kelas online hari ini.',
              style: TextStyle(color: Colors.grey)));
    }

    return Column(
      children: meetings.map((meeting) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Builder(
            builder: (context) {
              return ListTile(
                leading: const Icon(Icons.video_call, color: Colors.red),
                title: Text(meeting.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    'Pukul ${meeting.startTime.substring(11, 16)} - ${meeting.endTime.substring(11, 16)} (${meeting.platform})'),
                trailing: meeting.meetingLink.isNotEmpty
                    ? const Icon(Icons.chevron_right, color: Colors.red)
                    : null,
                onTap: () {
                  if (meeting.meetingLink.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Membuka link meeting untuk ${meeting.title}')),
                    );
                  }
                },
              );
            },
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
        _buildModuleItem(context, 'Materi', Icons.folder_open, Colors.blue,
            'Materi Pelajaran'),
        _buildModuleItem(context, 'Tugas', Icons.check_circle_outline,
            Colors.orange, 'Tugas & Nilai'),
        _buildModuleItem(
            context, 'Quiz', Icons.edit_note, Colors.green, 'Latihan & Quiz'),
        _buildModuleItem(
            context, 'Laporan', Icons.event_note, Colors.red, 'Laporan Harian'),
        _buildModuleItem(context, 'Nilai', Icons.bar_chart, Colors.purple,
            'Rangkuman Nilai'),
        _buildModuleItem(context, 'Pengaturan', Icons.settings, Colors.grey,
            'Pengaturan Akun'),
      ],
    );
  }

  Widget _buildModuleItem(BuildContext context, String label, IconData icon,
      Color color, String fullTitle) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Navigasi ke $fullTitle belum diimplementasikan.')),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 35, color: color),
            const SizedBox(height: 5),
            Text(label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}