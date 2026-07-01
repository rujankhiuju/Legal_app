import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool isNewer;

  const UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.isNewer,
  });
}

class UpdateCheckerNotifier extends StateNotifier<AsyncValue<UpdateInfo?>> {
  UpdateCheckerNotifier() : super(const AsyncValue.data(null));

  Future<void> checkForUpdate() async {
    state = const AsyncValue.loading();
    try {
      final info = await _fetchLatestRelease();
      state = AsyncValue.data(info);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<UpdateInfo?> _fetchLatestRelease() async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(
        Uri.parse('https://api.github.com/repos/rujankhiuju/Legal_app/releases/latest'),
      );
      request.headers.set('Accept', 'application/vnd.github.v3+json');
      request.headers.set('User-Agent', 'NepaliLegalAssistant');

      final response = await request.close();
      if (response.statusCode != 200) return null;

      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final tagName = data['tag_name'] as String? ?? '';
      final bodyText = data['body'] as String? ?? '';
      final assets = data['assets'] as List<dynamic>? ?? [];

      String? downloadUrl;
      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        if (name.contains('arm64-v8a') || name.endsWith('.apk')) {
          downloadUrl = asset['browser_download_url'] as String?;
          break;
        }
      }
      downloadUrl ??= data['html_url'] as String?;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final isNewer = _compareVersions(tagName.replaceAll(RegExp(r'^v'), ''), currentVersion);

      return UpdateInfo(
        latestVersion: tagName,
        downloadUrl: downloadUrl ?? '',
        releaseNotes: bodyText.isNotEmpty
            ? bodyText.split('\n').where((l) => l.trim().isNotEmpty).take(5).join('\n')
            : 'New version available.',
        isNewer: isNewer,
      );
    } finally {
      client.close();
    }
  }

  bool _compareVersions(String latest, String current) {
    try {
      final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < latestParts.length && i < currentParts.length; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return latestParts.length > currentParts.length;
    } catch (_) {
      return false;
    }
  }
}

final updateCheckerProvider =
    StateNotifierProvider<UpdateCheckerNotifier, AsyncValue<UpdateInfo?>>((ref) {
  return UpdateCheckerNotifier();
});
