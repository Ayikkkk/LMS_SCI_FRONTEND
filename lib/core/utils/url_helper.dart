// lib/core/utils/url_helper.dart

import '../network/api_client.dart';

/// Sanitasi URL gambar/file dari backend.
///
/// Menangani tiga kasus:
/// 1. URL dengan IP address + https:// → ganti ke http:// dan /storage/ → /api/files/
/// 2. URL relatif (path saja) → gabungkan dengan apiHost + /api/files/
/// 3. URL domain dengan https:// (Railway, dll.) → biarkan apa adanya
String? sanitizeMediaUrl(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  String url = raw.trim();

  // Kasus: URL dengan IP address (VPS tanpa SSL)
  if (RegExp(r'https?://\d+\.\d+\.\d+\.\d+').hasMatch(url)) {
    // Paksa http://
    url = url.replaceFirst('https://', 'http://');
    // Ganti /storage/ → /api/files/ agar tidak kena 403 Nginx
    url = url.replaceFirst('/storage/', '/api/files/');
    return url;
  }

  // Kasus: path relatif (tidak ada http/https)
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    final base = apiHost.replaceAll(RegExp(r'/+$'), '');
    final path = url.replaceAll(RegExp(r'^/+'), '');
    return '$base/api/files/$path';
  }

  // Kasus: URL domain lengkap (Railway, dll.) — biarkan apa adanya
  return url;
}
