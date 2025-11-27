// lib/features/profile/presentation/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Auth
import 'package:lms_frontend/features/auth/presentation/login_screen.dart';
import 'package:lms_frontend/features/auth/domain/auth_notifier.dart';

// Home Providers
import 'package:lms_frontend/features/home/presentation/providers/home_provider.dart';
import 'package:lms_frontend/features/home/data/repository/home_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Pengaturan Profil',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        _buildItem(context, 'Laporan Harian', Icons.event_note),
        _buildItem(context, 'Ganti Tema', Icons.color_lens),
        _buildItem(context, 'Pengaturan Aplikasi', Icons.settings),
        const Divider(),

        /// 🔥 Logout
        _buildItem(
          context,
          'Log Out',
          Icons.logout,
          isLogout: true,
          ref: ref,
        ),
      ],
    );
  }

  Widget _buildItem(
    BuildContext context,
    String title,
    IconData icon, {
    bool isLogout = false,
    WidgetRef? ref,
  }) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : Colors.blueGrey),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: !isLogout ? const Icon(Icons.chevron_right) : null,
      onTap: () async {
        if (!isLogout) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title diklik!')),
          );
          return;
        }

        // 🔥 Konfirmasi
        final confirm = await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Konfirmasi"),
            content: const Text("Yakin ingin logout?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Logout"),
              ),
            ],
          ),
        );

        if (confirm != true) return;

        // 🔥 1. Logout lewat AuthNotifier
        await ref!.read(authNotifierProvider.notifier).doLogout();

        // 🔥 2. Reset state Riverpod supaya data tidak membawa user lama
        ref.invalidate(authNotifierProvider);
        ref.invalidate(homeRepositoryProvider);
        ref.invalidate(dashboardDataProvider);

        // 🔥 3. Arahkan ke halaman login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      },
    );
  }
}
