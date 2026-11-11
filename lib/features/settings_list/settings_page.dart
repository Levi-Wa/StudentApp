import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../theme/app_theme.dart';
import '../../data/providers/app_state.dart';
import '../../data/providers/theme_provider.dart';
import '../../data/providers/text_size_provider.dart';
import '../../data/models/group.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/update_service.dart';
import '../../utils/responsive_text.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool pushNotifications = false;
  bool noteNotifications = false;
  String notificationPeriod = 'За день';
  bool _isUpdating = false;

  String? _selectedFormEdu;
  String? _selectedCourse;
  Group? _selectedGroup;

  // App Update state
  String _currentAppVersion = '1.0.1';
  bool _isCheckingUpdate = false;
  String? _updateStatusMessage;
  AppUpdateInfo? _availableUpdate;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
    _initializeCurrentGroup();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _currentAppVersion = info.version);
      }
    } catch (_) {}
  }

  void _loadNotificationSettings() async {
    final box = await Hive.openBox('notification_settings');
    if (mounted) {
      setState(() {
        pushNotifications =
            box.get('schedule_notifications', defaultValue: false);
        noteNotifications = box.get('note_notifications', defaultValue: false);
        notificationPeriod =
            box.get('notification_period', defaultValue: 'За день');
      });
    }
  }

  void _initializeCurrentGroup() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.loadGroups();

    final groupId = await appState.getSavedGroupId();
    final groupName = await appState.getSavedGroupName();

    if (groupId != null && groupName != null && mounted) {
      final currentGroup =
          appState.groups.where((g) => g.id == groupId).firstOrNull;

      if (currentGroup != null) {
        setState(() {
          _selectedFormEdu = currentGroup.formEdu;
          _selectedCourse = currentGroup.course.toString();
          _selectedGroup = currentGroup;
        });
      }
    }
  }

  Future<void> _checkAppUpdate() async {
    setState(() {
      _isCheckingUpdate = true;
      _updateStatusMessage = null;
    });

    try {
      final info = await UpdateService().checkForUpdate();
      if (!mounted) return;

      setState(() {
        _isCheckingUpdate = false;
        _availableUpdate = info;
        if (info == null) {
          _updateStatusMessage = 'Не удалось связаться с репозиторием';
        } else if (info.hasUpdate) {
          _updateStatusMessage = 'Доступна новая версия: v${info.latestVersion}!';
        } else {
          _updateStatusMessage =
              'У вас установлена последняя версия (v${info.currentVersion})';
        }
      });

      if (info != null && info.hasUpdate && mounted) {
        UpdateService.showUpdateModal(context, info);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
          _updateStatusMessage = 'Ошибка при проверке обновлений';
        });
      }
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Неизвестно';
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (isToday) {
      return 'Сегодня в $timeStr';
    }
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} в $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    // Watching ThemeProvider ensures 100% instant 0ms redraw when toggled
    context.watch<ThemeProvider>();
    final appState = Provider.of<AppState>(context);

    final bg = AppTheme.bg(context);
    final cardBg = AppTheme.secondaryBg(context);
    final surface = AppTheme.surface(context);
    final text = AppTheme.text(context);
    final subtext = AppTheme.subtext(context);
    final divider = AppTheme.divider(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        title: Text(
          'Настройки',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: text,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // App Update Section
          _buildUpdateSection(cardBg, surface, text, subtext, divider),
          const SizedBox(height: 16),

          // Current Group info & changer
          _buildGroupSection(appState, cardBg, surface, text, subtext, divider),
          const SizedBox(height: 16),

          // Schedule Sync section
          _buildSyncSection(appState, cardBg, surface, text, subtext, divider),
          const SizedBox(height: 16),

          // App Appearance & Notifications
          _buildAppearanceSection(cardBg, surface, text, subtext, divider),
          const SizedBox(height: 16),

          // Reset data
          _buildResetSection(appState, cardBg, text, subtext, divider),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildUpdateSection(
    Color cardBg,
    Color surface,
    Color text,
    Color subtext,
    Color divider,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.dockActiveAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: AppTheme.dockActiveAmber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Обновление приложения',
                  style: GoogleFonts.inter(
                    fontSize: ResponsiveText.title(context),
                    fontWeight: FontWeight.w700,
                    color: text,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'v$_currentAppVersion',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: subtext,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Проверка наличия новых версий и APK в официальном репозитории StudentApp.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: subtext,
              height: 1.35,
            ),
          ),
          if (_updateStatusMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _availableUpdate?.hasUpdate == true
                    ? AppTheme.dockActiveAmber.withValues(alpha: 0.12)
                    : surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    _availableUpdate?.hasUpdate == true
                        ? Icons.info_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 16,
                    color: _availableUpdate?.hasUpdate == true
                        ? AppTheme.dockActiveAmber
                        : const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _updateStatusMessage!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryAccent,
                    side: const BorderSide(color: AppTheme.primaryAccent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isCheckingUpdate ? null : _checkAppUpdate,
                  icon: _isCheckingUpdate
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded, size: 18),
                  label: Text(
                    _isCheckingUpdate ? 'Проверка...' : 'Проверить обновления',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (_availableUpdate?.hasUpdate == true) ...[
                const SizedBox(width: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.dockActiveAmber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () =>
                      UpdateService.showUpdateModal(context, _availableUpdate!),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(
                    'Скачать',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSection(
    AppState appState,
    Color cardBg,
    Color surface,
    Color text,
    Color subtext,
    Color divider,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_outlined,
                  color: AppTheme.primaryAccent, size: 22),
              const SizedBox(width: 8),
              Text(
                'Учебная группа',
                style: GoogleFonts.inter(
                  fontSize: ResponsiveText.title(context),
                  fontWeight: FontWeight.w700,
                  color: text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Текущая группа:',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: subtext,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appState.currentGroupName ?? 'Не выбрана',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: text,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Сменить группу:',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: subtext,
            ),
          ),
          const SizedBox(height: 10),

          // Form Edu Dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedFormEdu,
            decoration: InputDecoration(
              labelText: 'Форма обучения',
              filled: true,
              fillColor: surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: divider),
              ),
            ),
            items: appState.formEduOptions
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedFormEdu = value;
                _selectedCourse = null;
                _selectedGroup = null;
              });
              if (value != null) {
                appState.filterGroups(value, null);
              }
            },
          ),
          const SizedBox(height: 12),

          // Course Dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedCourse,
            decoration: InputDecoration(
              labelText: 'Курс',
              filled: true,
              fillColor: surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: divider),
              ),
            ),
            items: appState
                .getCourseOptions(_selectedFormEdu)
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedCourse = value;
                _selectedGroup = null;
              });
              if (value != null && _selectedFormEdu != null) {
                appState.filterGroups(_selectedFormEdu, value);
              }
            },
          ),
          const SizedBox(height: 12),

          // Group Dropdown
          DropdownButtonFormField<Group>(
            initialValue: _selectedGroup,
            decoration: InputDecoration(
              labelText: 'Группа',
              filled: true,
              fillColor: surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: divider),
              ),
            ),
            items: appState.groups
                .map((group) => DropdownMenuItem(
                      value: group,
                      child: Text(group.name),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedGroup = value;
              });
            },
          ),
          const SizedBox(height: 16),

          // Save / Apply group button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _selectedGroup != null ? _applyNewGroup : null,
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: const Text(
                'Сохранить и загрузить расписание',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncSection(
    AppState appState,
    Color cardBg,
    Color surface,
    Color text,
    Color subtext,
    Color divider,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync_rounded,
                  color: AppTheme.primaryAccent, size: 22),
              const SizedBox(width: 8),
              Text(
                'Обновление данных',
                style: GoogleFonts.inter(
                  fontSize: ResponsiveText.title(context),
                  fontWeight: FontWeight.w700,
                  color: text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Последняя синхронизация: ${_formatDateTime(appState.lastUpdated)}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: subtext,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryAccent,
                side: const BorderSide(color: AppTheme.primaryAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isUpdating ? null : _updateSchedule,
              icon: _isUpdating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 20),
              label: Text(_isUpdating ? 'Обновление...' : 'Обновить расписание'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(
    Color cardBg,
    Color surface,
    Color text,
    Color subtext,
    Color divider,
  ) {
    final themeProvider = context.watch<ThemeProvider>();
    final textSizeProvider = context.watch<TextSizeProvider>();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded,
                  color: AppTheme.primaryAccent, size: 22),
              const SizedBox(width: 8),
              Text(
                'Внешний вид и уведомления',
                style: GoogleFonts.inter(
                  fontSize: ResponsiveText.title(context),
                  fontWeight: FontWeight.w700,
                  color: text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Тёмная тема',
              style: GoogleFonts.inter(
                fontSize: ResponsiveText.body(context),
                fontWeight: FontWeight.w500,
                color: text,
              ),
            ),
            subtitle: Text(
              themeProvider.isDarkMode ? 'Включена' : 'Выключена',
              style: GoogleFonts.inter(fontSize: 12, color: subtext),
            ),
            value: themeProvider.isDarkMode,
            activeThumbColor: AppTheme.dockActiveAmber,
            onChanged: (_) => themeProvider.toggleTheme(),
          ),
          _buildTextSizeSelector(textSizeProvider, surface, text, divider),
          Divider(color: divider),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Уведомления об изменениях в расписании',
              style: GoogleFonts.inter(
                fontSize: ResponsiveText.body(context),
                fontWeight: FontWeight.w500,
                color: text,
              ),
            ),
            value: pushNotifications,
            activeThumbColor: AppTheme.primaryAccent,
            onChanged: (v) async {
              setState(() => pushNotifications = v);
              await NotificationService.setScheduleNotifications(v);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Уведомления о сроках заметок',
              style: GoogleFonts.inter(
                fontSize: ResponsiveText.body(context),
                fontWeight: FontWeight.w500,
                color: text,
              ),
            ),
            value: noteNotifications,
            activeThumbColor: AppTheme.primaryAccent,
            onChanged: (v) async {
              setState(() => noteNotifications = v);
              await NotificationService.setNoteNotifications(v);
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: notificationPeriod,
            decoration: InputDecoration(
              labelText: 'Напоминать о заметках за...',
              filled: true,
              fillColor: surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: divider),
              ),
            ),
            items: ['За день', 'За 3 дня', 'За 7 дней']
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (v) async {
              if (v != null) {
                setState(() => notificationPeriod = v);
                await NotificationService.setNotificationPeriod(v);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResetSection(
    AppState appState,
    Color cardBg,
    Color text,
    Color subtext,
    Color divider,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.delete_outline_rounded,
                  color: Colors.red, size: 22),
              const SizedBox(width: 8),
              Text(
                'Сброс данных',
                style: GoogleFonts.inter(
                  fontSize: ResponsiveText.title(context),
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Очистить сохраненную группу, расписание и заметки',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: subtext,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _showResetDialog,
              icon: const Icon(Icons.delete_forever_rounded, size: 20),
              label: const Text('Сбросить все настройки'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextSizeSelector(
    TextSizeProvider textSizeProvider,
    Color surface,
    Color text,
    Color divider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Размер шрифта',
            style: GoogleFonts.inter(
              fontSize: ResponsiveText.body(context),
              fontWeight: FontWeight.w500,
              color: text,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: divider),
            ),
            child: DropdownButton<String>(
              value: textSizeProvider.currentSizeLabel,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down),
              dropdownColor: surface,
              items: TextSizeProvider.textSizeOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option['label'] as String,
                  child: Text(
                    option['label'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: text,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  final option = TextSizeProvider.textSizeOptions.firstWhere(
                    (opt) => opt['label'] == value,
                  );
                  textSizeProvider
                      .setTextScaleFactor(option['value'] as double);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _applyNewGroup() async {
    if (_selectedGroup == null) return;

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      setState(() => _isUpdating = true);

      await appState.loadSchedule(
        _selectedGroup!.id,
        _selectedGroup!.name,
        forceUpdate: true,
      );

      setState(() => _isUpdating = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Группа успешно изменена на ${_selectedGroup!.name}'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при загрузке расписания: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateSchedule() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      setState(() => _isUpdating = true);

      final success = await appState.forceUpdateSchedule();
      setState(() => _isUpdating = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Расписание успешно обновлено с сервера'
                  : 'Ошибка обновления: проверьте интернет-соединение',
            ),
            backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сброс всех данных'),
        content: const Text(
          'Все сохраненные данные, настройки группы и расписание будут удалены. Вы уверены?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              final navigator = Navigator.of(context);
              Navigator.pop(context);
              final appState = Provider.of<AppState>(context, listen: false);
              await appState.resetApp();
              if (mounted) {
                navigator.pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }
}
