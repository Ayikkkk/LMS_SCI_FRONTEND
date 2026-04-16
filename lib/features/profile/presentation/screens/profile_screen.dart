import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/profile_provider.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../laporan_harian/presentation/screens/laporan_harian_screen.dart';
import '../screens/profile_detail_screen.dart';
import '../../../auth/presentation/change_password_screen.dart';

// THEME PROVIDER
import '../../../../core/theme/theme_notifier.dart';

// VERSION SERVICE
import '../../../../core/providers/version_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileData = ref.watch(profileDataProvider);

    // AMBIL THEME MODE
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: profileData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Gagal memuat data profil: $e")),
        data: (student) {
          final guru = student.guru;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(profileDataProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 10),

                // ============================
                // AKUN SISWA
                // ============================
                _sectionTitle("AKUN", context),
                _profileCard(context, ref, student),

                const SizedBox(height: 20),

                // ============================
                // GURU PEMBIMBING
                // ============================
                _sectionTitle("GURU AKADEMIK", context),
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
                _sectionTitle("PERSONALISASI & KEAMANAN", context),

                //  MODE GELAP AKTIF
                _switchItem(
                  title: "Mode Gelap",
                  icon: Icons.dark_mode_outlined,
                  value: isDark,
                  onChanged: (val) {
                    ref.read(themeNotifierProvider.notifier).toggle(val);
                  },
                ),

                _menuItem(
                  "Ganti Kata Sandi",
                  Icons.password_outlined,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen()),
                    );

                    try {
                      ref.invalidate(profileDataProvider);
                    } catch (_) {}
                  },
                ),

                const SizedBox(height: 30),

                // ============================
                // TENTANG APLIKASI
                // ============================
                _sectionTitle("TENTANG APLIKASI", context),

                _menuItem(
                  "Laporan Harian",
                  Icons.book_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LaporanHarianScreen()),
                    );
                  },
                ),

                _menuItem(
                  "Pengaduan",
                  Icons.support_agent_outlined,
                  onTap: () {},
                ),

                _versionItem(ref),

                const SizedBox(height: 30),

                // ============================
                // LOGOUT
                // ============================
                _logoutButton(context, ref),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================================
  // SECTION TITLE
  // ================================
  Widget _sectionTitle(String title, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey[400] : Colors.black54,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ================================
  // PROFILE CARD
  // ================================
  Widget _profileCard(BuildContext context, WidgetRef ref, dynamic student) {
    final name = (student?.name ?? "").toString();
    final nis = (student?.nis ?? student?.username ?? "-").toString();
    final className =
        (student?.className ?? student?.class_name ?? "-").toString();

    String? photoUrl;
    try {
      photoUrl = student?.photo ?? student?.photoUrl;
    } catch (_) {}

    Widget avatar;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      avatar = CircleAvatar(
        radius: 32,
        backgroundImage: NetworkImage(photoUrl),
      );
    } else {
      avatar = CircleAvatar(
        radius: 32,
        backgroundColor: Colors.blue,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : "?",
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileDetailScreen(student: student),
            ),
          );
          ref.invalidate(profileDataProvider);
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              avatar,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text("NIS: $nis",
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[300]
                              : Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        )),
                    const SizedBox(height: 4),
                    Text("Kelas • $className",
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[300]
                              : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        )),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }

  // ================================
  // TEACHER CARD
  // ================================
  Widget _teacherCard(String name, String email, String phone) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.email_outlined, color: Colors.blue),
                const SizedBox(width: 12),
                Text(email),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.call_outlined, color: Colors.green),
                const SizedBox(width: 12),
                Text(phone),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyTeacherCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Text("Belum ada guru pembimbing akademik"),
      ),
    );
  }

  // ================================
  // SWITCH ITEM (ACTIVE)
  // ================================
  Widget _switchItem({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(
          icon,
          color: value ? Colors.amber : Colors.grey,
        ),
        title: Text(title),
        subtitle: Text(
          value ? 'Aktif' : 'Nonaktif',
          style: TextStyle(
            fontSize: 12,
            color: value ? Colors.amber : Colors.grey,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.amber,
        ),
      ),
    );
  }

  // ================================
  // MENU ITEM
  // ================================
  Widget _menuItem(String title, IconData icon, {VoidCallback? onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Colors.purple),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  // ================================
  // VERSION ITEM
  // ================================
  Widget _versionItem(WidgetRef ref) {
    final version = ref.watch(currentVersionProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.info_outline, color: Colors.blue),
        title: const Text("Versi Aplikasi"),
        subtitle: Text(
          'v$version',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.transparent),
      ),
    );
  }

  // ================================
  // LOGOUT BUTTON
  // ================================
  Widget _logoutButton(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text(
          "Keluar Akun",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        onTap: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Konfirmasi"),
              content: const Text("Yakin ingin keluar akun?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Batal")),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Keluar")),
              ],
            ),
          );

          if (confirm != true) return;

          // doLogout() akan set state = unauthenticated
          // AuthRedirector akan otomatis redirect ke /login
          // Tidak perlu manual navigate atau invalidate di sini
          await ref.read(authNotifierProvider.notifier).doLogout();
        },
      ),
    );
  }
}
