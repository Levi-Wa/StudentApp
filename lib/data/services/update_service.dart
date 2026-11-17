import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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

  /// Extracts semantic version string (e.g. "1.0.4") from arbitrary text (like "v1.0.4", "Urse 1.0.4", "Release 1.0.4")
  static String extractVersion(String? text) {
    if (text == null || text.trim().isEmpty) return '';
    final match = RegExp(r'(\d+\.\d+(?:\.\d+)?)').firstMatch(text);
    return match?.group(1) ?? '';
  }

  /// Compares semantic versions (e.g. "1.0.2" vs "1.0.1").
  /// Returns 1 if v1 > v2, -1 if v1 < v2, 0 if equal.
  static int compareVersions(String v1, String v2) {
    final cleanV1 = extractVersion(v1);
    final cleanV2 = extractVersion(v2);

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
    String currentVersion = '1.0.5';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (packageInfo.version.isNotEmpty) {
        currentVersion = packageInfo.version;
      }
    } catch (_) {}

    // 1. Try GitHub Releases API first
    try {
      final response = await _dio.get(githubReleasesApi);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final rawTag = data['tag_name'] as String? ?? '';
        final rawName = data['name'] as String? ?? '';
        final body = data['body'] as String? ??
            'Новая версия приложения готова к установке.';

        // Extract semantic version: check both tag and release name, pick highest
        final verFromTag = extractVersion(rawTag);
        final verFromName = extractVersion(rawName);
        String latestVer = verFromTag;
        if (verFromName.isNotEmpty &&
            (latestVer.isEmpty ||
                compareVersions(verFromName, latestVer) > 0)) {
          latestVer = verFromName;
        }
        if (latestVer.isEmpty) {
          latestVer = rawTag.replaceAll('v', '').trim();
        }

        final title = rawName.isNotEmpty ? rawName : 'Обновление v$latestVer';

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

        final isNewer =
            latestVer.isNotEmpty && compareVersions(latestVer, currentVersion) > 0;
        return AppUpdateInfo(
          latestVersion: latestVer,
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

        final rawVer = data['version'] as String? ?? '';
        final rawTitle = data['title'] as String? ?? '';
        final verFromRaw = extractVersion(rawVer);
        final verFromTitle = extractVersion(rawTitle);
        String latestVer = verFromRaw;
        if (verFromTitle.isNotEmpty &&
            (latestVer.isEmpty ||
                compareVersions(verFromTitle, latestVer) > 0)) {
          latestVer = verFromTitle;
        }
        if (latestVer.isEmpty) {
          latestVer = rawVer.isNotEmpty ? rawVer : currentVersion;
        }

        final latestCode = (data['version_code'] as num?)?.toInt() ?? 0;
        final downloadUrl = data['download_url'] as String? ??
            'https://github.com/$githubOwner/$githubRepo/releases';
        final notes = data['release_notes'] as String? ??
            'Доступна свежая версия приложения.';
        final title = rawTitle.isNotEmpty ? rawTitle : 'Обновление v$latestVer';

        final isNewer =
            latestVer.isNotEmpty && compareVersions(latestVer, currentVersion) > 0;
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

  /// Checks and requests permission to install unknown packages on Android
  static Future<bool> ensureInstallPermission() async {
    if (Platform.isAndroid) {
      try {
        final status = await Permission.requestInstallPackages.status;
        if (!status.isGranted) {
          final result = await Permission.requestInstallPackages.request();
          return result.isGranted;
        }
      } catch (_) {}
    }
    return true;
  }

  /// Silently downloads APK in background for auto-update and triggers package installer
  static Future<void> performAutoUpdate(
      BuildContext context, String downloadUrl) async {
    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/student_app_update.apk';
      final file = File(savePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }

      final dio = Dio();
      await dio.download(downloadUrl, savePath);

      if (await file.exists() && await file.length() > 5000000) {
        await ensureInstallPermission();
        await OpenFilex.open(
          savePath,
          type: 'application/vnd.android.package-archive',
        );
      }
    } catch (_) {}
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
      if (await file.exists() && await file.length() > 5000000) {
        onProgress(1.0, 'Запуск установки...');
        await ensureInstallPermission();
        final result = await OpenFilex.open(
          savePath,
          type: 'application/vnd.android.package-archive',
        );

        if (result.type != ResultType.done) {
          await launchDownload(downloadUrl);
        }
        onComplete(null);
      } else {
        await launchDownload(downloadUrl);
        onComplete(null);
      }
    } catch (e) {
      String userFriendlyMessage = 'Не удалось загрузить обновление.';
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          userFriendlyMessage =
              'Релиз с файлом APK ещё не опубликован в репозитории GitHub (ошибка 404). Создайте Release на GitHub и прикрепите файл app-release.apk.';
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          userFriendlyMessage =
              'Превышено время ожидания сервера. Проверьте интернет или отключите VPN.';
        } else {
          userFriendlyMessage =
              'Ошибка загрузки (${e.response?.statusCode ?? 'сеть'}). Проверьте подключение.';
        }
      } else {
        userFriendlyMessage = 'Ошибка при установке: $e';
      }
      onComplete(userFriendlyMessage);
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
  bool _isReadyToInstall = false;
  String? _downloadedApkPath;
  bool _needsPermission = false;
  double _progress = 0.0;
  String _progressText = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkExistingApk();
  }

  Future<void> _checkExistingApk() async {
    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/student_app_update.apk';
      final file = File(savePath);
      if (await file.exists() && await file.length() > 5000000) {
        if (mounted) {
          setState(() {
            _downloadedApkPath = savePath;
            _isReadyToInstall = true;
            _progressText = 'APK уже загружен и готов к установке';
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _installApk() async {
    if (_downloadedApkPath == null) return;

    if (Platform.isAndroid) {
      final status = await Permission.requestInstallPackages.status;
      if (!status.isGranted) {
        final res = await Permission.requestInstallPackages.request();
        if (!res.isGranted) {
          if (mounted) {
            setState(() {
              _needsPermission = true;
              _errorMessage =
                  'Для установки APK разрешите установку из неизвестных источников в настройках и затем нажмите «Установить».';
            });
          }
          return;
        }
      }
    }

    if (mounted) {
      setState(() {
        _needsPermission = false;
        _errorMessage = null;
      });
    }

    final result = await OpenFilex.open(
      _downloadedApkPath!,
      type: 'application/vnd.android.package-archive',
    );

    if (result.type != ResultType.done && mounted) {
      if (result.type == ResultType.permissionDenied) {
        setState(() {
          _needsPermission = true;
          _errorMessage =
              'Отказано в доступе. Пожалуйста, разрешите установку из этого источника в настройках.';
        });
      } else {
        setState(() {
          _errorMessage =
              'Не удалось запустить установщик (${result.message}). Вы можете открыть файл через проводник или браузер.';
        });
      }
    }
  }

  void _startUpdate({bool forceRedownload = false}) async {
    if (!forceRedownload && _isReadyToInstall && _downloadedApkPath != null) {
      _installApk();
      return;
    }

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _progressText = 'Подготовка к загрузке...';
      _errorMessage = null;
      _needsPermission = false;
    });

    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/student_app_update.apk';
      final file = File(savePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }

      final dio = Dio();
      await dio.download(
        widget.info.downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (mounted) {
            if (total > 0) {
              final progress = received / total;
              final receivedMb = (received / (1024 * 1024)).toStringAsFixed(1);
              final totalMb = (total / (1024 * 1024)).toStringAsFixed(1);
              setState(() {
                _progress = progress;
                _progressText = '$receivedMb МБ / $totalMb МБ';
              });
            } else {
              final receivedMb = (received / (1024 * 1024)).toStringAsFixed(1);
              setState(() {
                _progress = 0.5;
                _progressText = '$receivedMb МБ скачано';
              });
            }
          }
        },
      );

      if (await file.exists() && await file.length() > 5000000) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _isReadyToInstall = true;
            _downloadedApkPath = savePath;
            _progress = 1.0;
            _progressText = 'Загрузка завершена. Запуск установщика...';
          });
          _installApk();
        }
      } else {
        throw Exception('Загруженный файл поврежден или слишком мал');
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Не удалось загрузить обновление.';
        if (e is DioException) {
          if (e.response?.statusCode == 404) {
            msg = 'Релиз с файлом APK ещё не опубликован в репозитории GitHub (ошибка 404). Создайте Release на GitHub и прикрепите файл app-release.apk.';
          } else if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            msg = 'Превышено время ожидания сервера. Проверьте интернет или отключите VPN.';
          } else {
            msg = 'Ошибка загрузки (${e.response?.statusCode ?? 'сеть'}). Проверьте подключение.';
          }
        } else {
          msg = 'Ошибка при установке: $e';
        }
        setState(() {
          _isDownloading = false;
          _errorMessage = msg;
        });
      }
    }
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
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: Colors.red,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: AppTheme.dockActiveAmber,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => UpdateService.launchDownload(
                      'https://github.com/${UpdateService.githubOwner}/${UpdateService.githubRepo}/releases',
                    ),
                    icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                    label: const Text(
                      'Открыть GitHub Releases в браузере',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Action button
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
            onPressed: _isDownloading
                ? null
                : (_isReadyToInstall ? _installApk : () => _startUpdate()),
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : Icon(
                    _needsPermission
                        ? Icons.security_rounded
                        : (_isReadyToInstall
                            ? Icons.install_mobile_rounded
                            : Icons.system_update_rounded),
                    size: 20,
                  ),
            label: Text(
              _isDownloading
                  ? 'Загрузка...'
                  : (_needsPermission
                      ? 'Разрешить и установить'
                      : (_isReadyToInstall ? 'Установить APK' : 'Обновить')),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          if (_isReadyToInstall && !_isDownloading) ...[
            const SizedBox(height: 6),
            Center(
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: subtextColor,
                ),
                onPressed: () => _startUpdate(forceRedownload: true),
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text(
                  'Скачать заново',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
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
