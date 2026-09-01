import 'dart:convert';
import 'package:http/http.dart' as http;

class AppUpdateInfo {
  final int build;
  final String tag;
  final String downloadUrl;
  final String pageUrl;
  final String notes;

  const AppUpdateInfo({
    required this.build,
    required this.tag,
    required this.downloadUrl,
    required this.pageUrl,
    required this.notes,
  });
}

class UpdateService {
  static const currentBuild = int.fromEnvironment('APP_BUILD', defaultValue: 0);
  static const currentSha = String.fromEnvironment('APP_SHA', defaultValue: 'local');
  static const _latestReleaseApi =
      'https://api.github.com/repos/Lucas550x/familia-financas/releases/latest';

  Future<AppUpdateInfo?> check() async {
    final response = await http
        .get(
          Uri.parse(_latestReleaseApi),
          headers: const {'Accept': 'application/vnd.github+json'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final tag = (data['tag_name'] as String?) ?? '';
    final match = RegExp(r'build-(\d+)').firstMatch(tag);
    if (match == null) return null;
    final latestBuild = int.tryParse(match.group(1) ?? '') ?? 0;
    if (latestBuild <= currentBuild) return null;

    String apkUrl = '';
    final assets = (data['assets'] as List?) ?? const [];
    for (final item in assets) {
      final asset = Map<String, dynamic>.from(item as Map);
      final name = (asset['name'] as String?) ?? '';
      if (name.endsWith('.apk')) {
        apkUrl = (asset['browser_download_url'] as String?) ?? '';
        break;
      }
    }

    return AppUpdateInfo(
      build: latestBuild,
      tag: tag,
      downloadUrl: apkUrl,
      pageUrl: (data['html_url'] as String?) ?? '',
      notes: (data['body'] as String?) ?? '',
    );
  }
}
