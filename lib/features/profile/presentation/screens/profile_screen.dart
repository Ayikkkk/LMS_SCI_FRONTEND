// lib/features/profile/presentation/screens/profile_screen.dart

import 'package:flutter/material.dart';

// Halaman Profil (dengan daftar setting)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Pengaturan Profil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        _buildProfileTile(context, 'Laporan Harian', Icons.event_note),
        _buildProfileTile(context, 'Ganti Tema', Icons.color_lens),
        _buildProfileTile(context, 'Pengaturan Aplikasi', Icons.settings),
        const Divider(),
        _buildProfileTile(context, 'Log Out', Icons.logout, isLogout: true),
      ],
    );
  }

  Widget _buildProfileTile(BuildContext context, String title, IconData icon,
      {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : Colors.blueGrey),
      title: Text(title,
          style: TextStyle(
              color: isLogout ? Colors.red : Colors.black,
              fontWeight: FontWeight.w500)),
      trailing: !isLogout ? const Icon(Icons.chevron_right) : null,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title diklik!')),
        );
      },
    );
  }
}