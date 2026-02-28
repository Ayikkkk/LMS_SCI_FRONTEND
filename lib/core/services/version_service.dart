// lib/core/services/version_service.dart

import 'package:package_info_plus/package_info_plus.dart';
import '../network/api_client.dart';
import '../utils/logger.dart';

/// Service for handling app version checking and updates
class VersionService {
  static PackageInfo? _packageInfo;

  /// Initialize version service
  static Future<void> initialize() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      AppLogger.success(
        'Version service initialized: v${_packageInfo!.version}',
        'VersionService',
      );
    } catch (e) {
      AppLogger.error(
        'Failed to initialize version service',
        e,
        null,
        'VersionService',
      );
    }
  }

  /// Get current app version
  static String get currentVersion => _packageInfo?.version ?? '1.0.0';

  /// Get current build number
  static String get buildNumber => _packageInfo?.buildNumber ?? '1';

  /// Get app name
  static String get appName => _packageInfo?.appName ?? 'LMS Frontend';

  /// Get package name
  static String get packageName =>
      _packageInfo?.packageName ?? 'com.example.lms_frontend';

  /// Get full version string (version+build)
  static String get fullVersion => 'v$currentVersion ($buildNumber)';

  /// Check if update is available
  static Future<VersionCheckResult> checkForUpdate() async {
    try {
      AppLogger.debug('Checking for app updates...', 'VersionService');

      final response = await dio.get('/app/version');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final latestVersion = data['version'] as String;
        final minVersion = data['min_version'] as String?;
        final updateUrl = data['update_url'] as String?;
        final releaseNotes = data['release_notes'] as String?;
        final forceUpdate = data['force_update'] as bool? ?? false;

        final isUpdateAvailable =
            _isNewerVersion(latestVersion, currentVersion);
        final isForceUpdate =
            minVersion != null && _isNewerVersion(minVersion, currentVersion);

        AppLogger.info(
          'Version check: Current=$currentVersion, Latest=$latestVersion, Update=${isUpdateAvailable ? 'Available' : 'Not needed'}',
          'VersionService',
        );
        
        return VersionCheckResult(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          minVersion: minVersion,
          isUpdateAvailable: isUpdateAvailable,
          isForceUpdate: isForceUpdate || forceUpdate,
          updateUrl: updateUrl,
          releaseNotes: releaseNotes,
        );
      }

      // If endpoint doesn't exist or returns error, assume no update
      return VersionCheckResult(
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        isUpdateAvailable: false,
        isForceUpdate: false,
      );
    } catch (e) {
      AppLogger.warning(
        'Version check failed: ${e.toString()}',
        'VersionService',
      );

      // Return no update on error
      return VersionCheckResult(
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        isUpdateAvailable: false,
        isForceUpdate: false,
      );
    }
  }

  /// Compare two version strings
  /// Returns true if version1 is newer than version2
  static bool _isNewerVersion(String version1, String version2) {
    try {
      final v1Parts = version1.split('.').map(int.parse).toList();
      final v2Parts = version2.split('.').map(int.parse).toList();

      // Pad shorter version with zeros
      while (v1Parts.length < v2Parts.length) {
        v1Parts.add(0);
      }
      while (v2Parts.length < v1Parts.length) {
        v2Parts.add(0);
      }

      // Compare each part
      for (int i = 0; i < v1Parts.length; i++) {
        if (v1Parts[i] > v2Parts[i]) return true;
        if (v1Parts[i] < v2Parts[i]) return false;
      }

      return false; // Versions are equal
    } catch (e) {
      AppLogger.error(
        'Failed to compare versions',
        e,
        null,
        'VersionService',
      );
      return false;
    }
  }

  /// Check if version service is initialized
  static bool get isInitialized => _packageInfo != null;
}

/// Result of version check
class VersionCheckResult {
  final String currentVersion;
  final String latestVersion;
  final String? minVersion;
  final bool isUpdateAvailable;
  final bool isForceUpdate;
  final String? updateUrl;
  final String? releaseNotes;

  VersionCheckResult({
    required this.currentVersion,
    required this.latestVersion,
    this.minVersion,
    required this.isUpdateAvailable,
    required this.isForceUpdate,
    this.updateUrl,
    this.releaseNotes,
  });

  /// Check if update is optional (not forced)
  bool get isOptionalUpdate => isUpdateAvailable && !isForceUpdate;

  @override
  String toString() {
    return 'VersionCheckResult(current: $currentVersion, latest: $latestVersion, updateAvailable: $isUpdateAvailable, forceUpdate: $isForceUpdate)';
  }
}
