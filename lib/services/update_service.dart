import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/app_version.dart';
import '../utils/constants.dart';

/// Holds information about a pending app update from GitHub Releases.
class UpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;

  const UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
  });
}

/// Checks the GitHub Releases API for newer versions of the app.
class UpdateService {
  UpdateService._();

  /// Timeout for the GitHub API call.
  static const Duration _timeout = Duration(seconds: 10);

  /// Returns [UpdateInfo] when a newer release is available, or `null` if the
  /// app is up-to-date, the API fails, or the user is offline.
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final uri = Uri.parse(
        'https://api.github.com/repos/'
        '${AppConstants.gitHubOwner}/${AppConstants.gitHubRepo}'
        '/releases/latest',
      );

      final response = await http
          .get(uri, headers: {'Accept': 'application/vnd.github.v3+json'})
          .timeout(_timeout);

      if (response.statusCode != 200) return null;

      final body = json.decode(response.body) as Map<String, dynamic>;
      final tagName = body['tag_name'] as String? ?? '';
      final releaseBody = body['body'] as String? ?? '';

      // Strip leading 'v' if present (e.g. "v0.3.0" → "0.3.0").
      final remoteVersion = tagName.replaceFirst(RegExp(r'^v'), '');

      // Read the actually-installed version at runtime (from the APK's
      // package info) rather than a hardcoded constant, so the comparison
      // matches whatever build the user is running.
      final installedVersion = await AppVersion.get();
      if (!_isNewer(remoteVersion, installedVersion)) return null;

      // Find the first APK asset in the release.
      final assets = body['assets'] as List<dynamic>?;
      String downloadUrl = '';
      if (assets != null) {
        for (final asset in assets) {
          final name = (asset['name'] as String? ?? '').toLowerCase();
          if (name.endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'] as String? ?? '';
            break;
          }
        }
      }

      // Fall back to the release's html_url (GitHub release page) if no APK
      // asset was found.
      if (downloadUrl.isEmpty) {
        downloadUrl = body['html_url'] as String? ?? '';
      }

      return UpdateInfo(
        latestVersion: remoteVersion,
        downloadUrl: downloadUrl,
        releaseNotes: releaseBody.trim(),
      );
    } catch (_) {
      // Silently swallow network / parsing errors — the update check must
      // never block or crash the app.
      return null;
    }
  }

  /// Returns `true` if [remote] is strictly newer than [current].
  ///
  /// Both strings are expected in "major.minor.patch" format.
  static bool _isNewer(String remote, String current) {
    final r = _parseVersion(remote);
    final c = _parseVersion(current);
    if (r == null || c == null) return false;

    for (var i = 0; i < 3; i++) {
      if (r[i] > c[i]) return true;
      if (r[i] < c[i]) return false;
    }
    return false; // same version
  }

  /// Parses "major.minor.patch" into a list of 3 ints, or `null` on failure.
  static List<int>? _parseVersion(String version) {
    final parts = version.split('.');
    if (parts.length != 3) return null;
    try {
      return parts.map((p) => int.parse(p)).toList();
    } catch (_) {
      return null;
    }
  }
}
