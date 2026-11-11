import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class AppUpdateInfo {
  final String latestVersion;
  final int latestVersionCode;
  final String currentVersion;
  final String releaseNotes;
  final String downloadUrl;
  final bool hasUpdate;
  final String? title;

  AppUpdateInfo({
    required this.latestVersion,
    required this.latestVersionCode,
    required this.currentVersion,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.hasUpdate,
    this.title,
  });
}

class UpdateService {
  static const String githubOwner = 'Levi-Wa';
  static const String githubRepo = 'StudentApp';
  static const String githubReleasesApi =
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';
  static const String rawManifestUrl =
      'https://raw.githubusercontent.com/$githubOwner/$githubRepo/main/version.json';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/vnd.github.v3+json',
      },
    ),
  );

  /// Compares semantic versions (e.g. "1.0.2" vs "1.0.1").
  /// Returns 1 if v1 > v2, -1 if v1 < v2, 0 if equal.
  static int compareVersions(String v1, String v2) {
    final cleanV1 = v1.replaceAll(RegExp(r'[^0-9.]'), '');
    final cleanV2 = v2.replaceAll(RegExp(r'[^0-9.]'), '');

    final parts1 =
        cleanV1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 =
        cleanV2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen =
        parts1.length > parts2.length ? parts1.length : parts2.length;
    while (parts1.length < maxLen) {
      parts1.add(0);
    }
    while (parts2.length < maxLen) {
      parts2.add(0);
    }

    for (int i = 0; i < maxLen; i++) {
      if (parts1[i] > parts2[i]) return 1;
      if (parts1[i] < parts2[i]) return -1;
    }
    return 0;
  }

  /// Checks if an update is available on GitHub
  Future<AppUpdateInfo?> checkForUpdate() async {
    String currentVersion = '1.0.1';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      currentVersion = packageInfo.version;
    } catch (_) {}

    // 1. Try GitHub Releases API first
    try {
      final response = await _dio.get(githubReleasesApi);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final tagName =
            (data['tag_name'] as String? ?? '').replaceAll('v', '').trim();
        final body = data['body'] as String? ??
            'Новая версия приложения готова к установке.';
        final title = data['name'] as String? ?? 'Обновление $tagName';

        // Search for APK in release assets
        String downloadUrl = data['html_url'] as String? ??
            'https://github.com/$githubOwner/$githubRepo/releases';
        final assets = data['assets'] as List<dynamic>?;
        if (assets != null && assets.isNotEmpty) {
          for (final asset in assets) {
            final name = (asset['name'] as String? ?? '').toLowerCase();
            if (name.endsWith('.apk')) {
              downloadUrl =
                  asset['browser_download_url'] as String? ?? downloadUrl;
              break;
            }
          }
        }

        final isNewer = compareVersions(tagName, currentVersion) > 0;
        return AppUpdateInfo(
          latestVersion: tagName,
          latestVersionCode: 0,
          currentVersion: currentVersion,
          releaseNotes: body,
          downloadUrl: downloadUrl,
          hasUpdate: isNewer,
          title: title,
        );
      }
    } catch (_) {}

    // 2. Fallback to raw version.json on main branch
    try {
      final response = await _dio.get(rawManifestUrl);
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> data = response.data is String
            ? jsonDecode(response.data as String)
            : response.data as Map<String, dynamic>;

        final latestVer = (data['version'] as String? ?? currentVersion).trim();
        final latestCode = (data['version_code'] as num?)?.toInt() ?? 0;
        final downloadUrl = data['download_url'] as String? ??
            'https://github.com/$githubOwner/$githubRepo/releases';
        final notes = data['release_notes'] as String? ??
            'Доступна свежая версия приложения.';
        final title = data['title'] as String? ?? 'Обновление v$latestVer';

        final isNewer = compareVersions(latestVer, currentVersion) > 0;
        return AppUpdateInfo(
          latestVersion: latestVer,
          latestVersionCode: latestCode,
          currentVersion: currentVersion,
          releaseNotes: notes,
          downloadUrl: downloadUrl,
          hasUpdate: isNewer,
          title: title,
        );
      }
    } catch (_) {}

    return null;
  }

  /// Downloads APK in background and automatically opens the package installer
  static Future<void> downloadAndInstallApk(
    BuildContext context,
    String downloadUrl, {
    required Function(double progress, String status) onProgress,
    required Function(String? error) onComplete,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/student_app_update.apk';

      // Remove existing old update file if present
      final file = File(savePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }

      final dio = Dio();
      await dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            final receivedMb = (received / (1024 * 1024)).toStringAsFixed(1);
            final totalMb = (total / (1024 * 1024)).toStringAsFixed(1);
            onProgress(progress, '$receivedMb МБ / $totalMb МБ');
          } else {
            final receivedMb = (received / (1024 * 1024)).toStringAsFixed(1);
            onProgress(0.5, '$receivedMb МБ скачано');
          }
        },
      );

      // Verify file exists and has size
      if (await file.exists() && await file.length() > 100000) {
        onProgress(1.0, 'Запуск установки...');
        final result = await OpenFilex.open(
          savePath,
          type: 'application/vnd.android.package-archive',
        );

        if (result.type != ResultType.done) {
          // If OpenFile failed, fallback to external launcher
          await launchDownload(downloadUrl);
        }
        onComplete(null);
      } else {
        // Fallback to browser
        await launchDownload(downloadUrl);
        onComplete(null);
      }
    } catch (e) {
      // In case of error, fallback to browser
      await launchDownload(downloadUrl);
      onComplete(e.toString());
    }
  }

  /// Opens the APK download or release link externally
  static Future<bool> launchDownload(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Displays the interactive update modal with in-app background download & installer prompt
  static void showUpdateModal(BuildContext context, AppUpdateInfo info) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UpdateModalContent(info: info),
    );
  }
}

class _UpdateModalContent extends StatefulWidget {
  final AppUpdateInfo info;

  const _UpdateModalContent({required this.info});

  @override
  State<_UpdateModalContent> createState() => _UpdateModalContentState();
}

class _UpdateModalContentState extends State<_UpdateModalContent> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _progressText = '';
  String? _errorMessage;

  void _startUpdate() {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _progressText = 'Подготовка к загрузке...';
      _errorMessage = null;
    });

    UpdateService.downloadAndInstallApk(
      context,
      widget.info.downloadUrl,
      onProgress: (progress, status) {
        if (mounted) {
          setState(() {
            _progress = progress;
            _progressText = status;
          });
        }
      },
      onComplete: (error) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _errorMessage = error;
          });
          if (error == null) {
            Navigator.pop(context);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E2229) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFF1F5F9) : const Color(0xFF191D23);
    final subtextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: subtextColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Rocket Icon & Title
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.dockActiveAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: AppTheme.dockActiveAmber,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.info.title ?? 'Доступно обновление',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF262C36)
                                : const Color(0xFFEFF2F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'v${widget.info.currentVersion}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: subtextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: subtextColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.dockActiveAmber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'v${widget.info.latestVersion}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.dockActiveAmber,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Release notes box
          Text(
            'Что нового в этой версии:',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 160),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  isDark ? const Color(0xFF13151A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF2B323C) : const Color(0xFFE2E8F0),
              ),
            ),
            child: SingleChildScrollView(
              child: Text(
                widget.info.releaseNotes,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.45,
                  color: textColor.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),

          if (_isDownloading) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF13151A)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.dockActiveAmber.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Загрузка обновления...',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.dockActiveAmber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      backgroundColor: isDark
                          ? const Color(0xFF28303C)
                          : const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.dockActiveAmber,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  if (_progressText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _progressText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              'Не удалось автоматически установить APK: $_errorMessage. Открываю браузер...',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Action buttons: "Обновить" instead of "Скачать"
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.dockActiveAmber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            onPressed: _isDownloading ? null : _startUpdate,
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.system_update_rounded, size: 20),
            label: Text(
              _isDownloading ? 'Загрузка...' : 'Обновить',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (!_isDownloading)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: subtextColor,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Напомнить позже',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
