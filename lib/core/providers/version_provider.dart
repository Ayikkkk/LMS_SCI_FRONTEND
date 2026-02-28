// lib/core/providers/version_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/version_service.dart';

/// Provider for version check
final versionCheckProvider = FutureProvider<VersionCheckResult>((ref) async {
  return await VersionService.checkForUpdate();
});

/// Provider for current app version
final currentVersionProvider = Provider<String>((ref) {
  return VersionService.currentVersion;
});

/// Provider for full version string
final fullVersionProvider = Provider<String>((ref) {
  return VersionService.fullVersion;
});
