// lib/features/profile/presentation/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/profile_provider.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../auth/presentation/login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileData = ref.watch(profileDataProvider);

    return Container(
      color: Colors.white,
      child: profileData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Gagal memuat data profil: $e")),
        data: (student) {
          final guru = student.guru;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 10),

              // ============================
              // AKUN SISWA
              // ============================
              _sectionTitle("AKUN"),
              _profileCard(
                student.name,
                student.nis ?? student.username,
                student.className ?? "-",
              ),

              const SizedBox(height: 20),

              // ============================
              // GURU PEMBIMBING
              // ============================
              _sectionTitle("GURU AKADEMIK"),

              guru == null
                  ? _emptyTeacherCard()
                  : _teacherCard(
                      guru.name,
                      guru.email ?? "-",
                      guru.phone ?? "-",
                    ),

              const SizedBox(height: 20),

              // ============================
              // PERSONALISASI
              // ============================
              _sectionTitle("PERSONALISASI"),
              _switchItem("Mode Gelap", Icons.dark_mode_outlined, false),

              const SizedBox(height: 20),

              // ============================
              // TENTANG APLIKASI
              // ============================
              _sectionTitle("TENTANG APLIKASI"),

              _menuItem(
                "Laporan Harian",
                Icons.book_outlined,
                onTap: () {},
              ),

              _menuItem(
                "Pengaduan",
                Icons.support_agent_outlined,
                onTap: () {},
              ),

              const SizedBox(height: 30),

              // ============================
              // LOGOUT
              // ============================
              _logoutButton(context, ref),
              const SizedBox(height: 50),
            ],
          );
        },
      ),
    );
  }

  // ================================
  // SECTION TITLE
  // ================================
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ================================
  // PROFILE CARD
  // ================================
  Widget _profileCard(String name, String nis, String className) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 32,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 35, color: Colors.white),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  const SizedBox(height: 6),

                  Text("NIS: $nis",
                      style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                  const SizedBox(height: 4),

                  Text("Kelas • $className",
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================
  // TEACHER CARD
  // ================================
  Widget _teacherCard(String name, String email, String phone) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            const SizedBox(height: 14),

            Row(
              children: [
                const Icon(Icons.email_outlined, color: Colors.blue),
                const SizedBox(width: 12),
                Text(email, style: const TextStyle(color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.call_outlined, color: Colors.green),
                const SizedBox(width: 12),
                Text(phone, style: const TextStyle(color: Colors.black87)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================================
  // EMPTY TEACHER
  // ================================
  Widget _emptyTeacherCard() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Text(
          "Belum ada guru pembimbing akademik",
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }

  // ================================
  // SWITCH ITEM
  // ================================
  Widget _switchItem(String title, IconData icon, bool value) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(color: Colors.black)),
        trailing: Switch(
          value: value,
          onChanged: (_) {},
        ),
      ),
    );
  }

  // ================================
  // MENU ITEM
  // ================================
  Widget _menuItem(String title, IconData icon, {VoidCallback? onTap}) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Colors.purple),
        title: Text(title, style: const TextStyle(color: Colors.black)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black45),
        onTap: onTap,
      ),
    );
  }

  // ================================
  // LOGOUT BUTTON
  // ================================
  Widget _logoutButton(BuildContext context, WidgetRef ref) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text(
          "Keluar Akun",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        onTap: () async {
          final konfirmasi = await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Konfirmasi"),
              content: const Text("Yakin ingin keluar akun?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Keluar"),
                ),
              ],
            ),
          );

          if (konfirmasi != true) return;

          await ref.read(authNotifierProvider.notifier).doLogout();
          ref.invalidate(authNotifierProvider);

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
      ),
    );
  }
}
