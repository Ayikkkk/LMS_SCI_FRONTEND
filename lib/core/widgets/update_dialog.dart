// lib/core/widgets/update_dialog.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/version_service.dart';

/// Dialog to show when app update is available
class UpdateDialog extends StatelessWidget {
  final VersionCheckResult versionCheck;

  const UpdateDialog({
    super.key,
    required this.versionCheck,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !versionCheck.isForceUpdate,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              versionCheck.isForceUpdate ? Icons.warning : Icons.info_outline,
              color: versionCheck.isForceUpdate ? Colors.red : Colors.blue,
            ),
            const SizedBox(width: 8),
            Text(
              versionCheck.isForceUpdate
                  ? 'Update Diperlukan'
                  : 'Update Tersedia',
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                versionCheck.isForceUpdate
                    ? 'Versi aplikasi Anda sudah tidak didukung. Silakan update ke versi terbaru untuk melanjutkan.'
                    : 'Versi baru aplikasi tersedia dengan fitur dan perbaikan terbaru.',
              ),
              const SizedBox(height: 16),
              _buildVersionInfo('Versi Saat Ini', versionCheck.currentVersion),
              _buildVersionInfo('Versi Terbaru', versionCheck.latestVersion),
              if (versionCheck.releaseNotes != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Yang Baru:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(versionCheck.releaseNotes!),
              ],
            ],
          ),
        ),
        actions: [
          if (!versionCheck.isForceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Nanti'),
            ),
          ElevatedButton(
            onPressed: () => _handleUpdate(context),
            child: const Text('Update Sekarang'),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo(String label, String version) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            version,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpdate(BuildContext context) async {
    if (versionCheck.updateUrl != null) {
      final uri = Uri.parse(versionCheck.updateUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat membuka link update'),
            ),
          );
        }
      }
    } else {
      // Default to Play Store if no URL provided
      final playStoreUrl = Uri.parse(
        'https://play.google.com/store/apps/details?id=${VersionService.packageName}',
      );
      if (await canLaunchUrl(playStoreUrl)) {
        await launchUrl(playStoreUrl, mode: LaunchMode.externalApplication);
      }
    }

    if (context.mounted && !versionCheck.isForceUpdate) {
      Navigator.of(context).pop();
    }
  }

  /// Show update dialog
  static Future<void> show(
    BuildContext context,
    VersionCheckResult versionCheck,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: !versionCheck.isForceUpdate,
      builder: (context) => UpdateDialog(versionCheck: versionCheck),
    );
  }
}
