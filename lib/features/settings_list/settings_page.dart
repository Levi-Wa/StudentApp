import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import '../../theme/app_theme.dart';
import '../../data/providers/app_state.dart';
import '../../data/providers/theme_provider.dart';
import '../../data/providers/text_size_provider.dart';
import '../../data/models/group.dart';
import '../../data/services/notification_service.dart';
import '../../utils/responsive_text.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool pushNotifications = false;
  bool noteNotifications = false;
  String notificationPeriod = 'За день';
  bool _isUpdating = false;
  
  String? _selectedFormEdu;
  String? _selectedCourse;
  Group? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
    // Временно отключаем _loadGroups() чтобы избежать проблем с Consumer'ами
    // _loadGroups();
  }

  Future<void> _loadGroups() async {
    print('SettingsPage: Загружаю группы');
    try {
      await Provider.of<AppState>(context, listen: false).loadGroups();
      print('SettingsPage: Группы загружены успешно');
    } catch (e) {
      print('SettingsPage: Ошибка загрузки групп: $e');
    }
  }
  
  void _loadNotificationSettings() async {
    final box = await Hive.openBox('notification_settings');
    setState(() {
      pushNotifications = box.get('schedule_notifications', defaultValue: false);
      noteNotifications = box.get('note_notifications', defaultValue: false);
      notificationPeriod = box.get('notification_period', defaultValue: 'За день');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: Column(
        children: [
          SizedBox(height: 60),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, size: 45, color: AppTheme.primaryText),
                  onPressed: () => Navigator.pop(context),
                ),
                Spacer(),
                Text(
                  'Настройки',
                  style: GoogleFonts.robotoCondensed(
                    fontSize: ResponsiveText.headline(context),
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                Card(
                  color: AppTheme.secondaryBackground,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Общие настройки',
                          style: GoogleFonts.robotoCondensed(
                              fontSize: ResponsiveText.title(context), fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 16),
                        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return _buildSwitch('Темная тема', themeProvider.isDarkMode,
                (v) => themeProvider.toggleTheme());
          },
        ),
                        Consumer<TextSizeProvider>(
                          builder: (context, textSizeProvider, child) {
                            return _buildTextSizeSelector(textSizeProvider);
                          },
                        ),
                        SizedBox(height: 16),
                        _buildSwitch(
                            'Push уведомления об изменении в расписании',
                            pushNotifications,
                            (v) async {
                              setState(() => pushNotifications = v);
                              await NotificationService.setScheduleNotifications(v);
                            }),
                        _buildSwitch(
                            'Push уведомления об истечении срока заметки',
                            noteNotifications,
                            (v) async {
                              setState(() => noteNotifications = v);
                              await NotificationService.setNoteNotifications(v);
                            }),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: notificationPeriod,
                          decoration:
                              InputDecoration(labelText: 'За сколько...'),
                          items: ['За день', 'За 3 дня', 'За 7 дней']
                              .map((item) => DropdownMenuItem(
                                  value: item, child: Text(item)))
                              .toList(),
                          onChanged: (v) async {
                            setState(() => notificationPeriod = v!);
                            await NotificationService.setNotificationPeriod(v!);
                          },
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _saveGeneralSettings,
                          child: Text('Сохранить'),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  color: AppTheme.secondaryBackground,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Настройки расписания',
                          style: GoogleFonts.robotoCondensed(
                              fontSize: ResponsiveText.title(context), fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 16),
                        Column(
                          children: [
                        Consumer<AppState>(
                          builder: (context, appState, child) {
                            return DropdownButtonFormField<String>(
                                  value: _selectedFormEdu,
                                  decoration: InputDecoration(labelText: 'Форма обучения'),
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
                            );
                                  },
                                ),
                                SizedBox(height: 16),
                            Consumer<AppState>(
                              builder: (context, appState, child) {
                                return DropdownButtonFormField<String>(
                                  value: _selectedCourse,
                                  decoration: InputDecoration(labelText: 'Курс'),
                                  items: appState.getCourseOptions(_selectedFormEdu)
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
                                );
                                  },
                                ),
                                SizedBox(height: 16),
                            Consumer<AppState>(
                              builder: (context, appState, child) {
                                return DropdownButtonFormField<Group>(
                                  value: _selectedGroup,
                                  decoration: InputDecoration(labelText: 'Группа'),
                                  items: appState.groups
                                      .map((group) => DropdownMenuItem(
                                          value: group, 
                                          child: Text(group.name)))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedGroup = value;
                                    });
                                  },
                                );
                                  },
                                ),
                              ],
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _isUpdating ? null : _updateSchedule,
                                child: _isUpdating 
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text('Обновить'),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _showResetDialog,
                                child: Text('Сбросить'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(
        title, 
        style: GoogleFonts.robotoCondensed(fontSize: ResponsiveText.subtitle(context)),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppTheme.primaryText,
      inactiveTrackColor: AppTheme.alternate,
    );
  }

  Widget _buildTextSizeSelector(TextSizeProvider textSizeProvider) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      title: Padding(
        padding: EdgeInsets.only(left: 16),
        child: Text(
          'Размер текста',
          style: GoogleFonts.robotoCondensed(
            fontSize: ResponsiveText.subtitle(context),
          ),
        ),
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 4, left: 16),
        child: Text(
          textSizeProvider.currentSizeLabel,
          style: GoogleFonts.inter(
            fontSize: ResponsiveText.small(context),
            color: Colors.grey[600],
          ),
        ),
      ),
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.primaryText.withOpacity(0.7),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<String>(
          value: textSizeProvider.currentSizeLabel,
          underline: Container(),
          icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryText),
          style: GoogleFonts.robotoCondensed(
            fontSize: ResponsiveText.body(context),
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryText,
          ),
          dropdownColor: AppTheme.secondaryBackground,
          items: TextSizeProvider.textSizeOptions.map((option) {
            return DropdownMenuItem<String>(
              value: option['label'] as String,
              child: Text(
                option['label'] as String,
                style: GoogleFonts.robotoCondensed(
                  fontSize: ResponsiveText.body(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              final option = TextSizeProvider.textSizeOptions.firstWhere(
                (opt) => opt['label'] == value,
              );
              textSizeProvider.setTextScaleFactor(option['value'] as double);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (v) {},
    );
  }

  void _saveGeneralSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Настройки сохранены'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _updateSchedule() async {
    print('SettingsPage: Нажата кнопка "Обновить"');
    print('SettingsPage: _selectedFormEdu: $_selectedFormEdu');
    print('SettingsPage: _selectedCourse: $_selectedCourse');
    print('SettingsPage: _selectedGroup: $_selectedGroup');

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      setState(() => _isUpdating = true);
      
      if (_selectedGroup != null) {
        print('SettingsPage: Обновляю для новой группы ${_selectedGroup!.name}');
        // Обновляем для новой группы
        await appState.loadSchedule(_selectedGroup!.id, _selectedGroup!.name);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Расписание обновлено для группы ${_selectedGroup!.name}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final hasGroup = await appState.hasSelectedGroup();
        print('SettingsPage: Группа сохранена: $hasGroup');

        if (hasGroup) {
          print('SettingsPage: Обновляю текущую группу');
        // Обновляем текущую группу
        await appState.forceUpdateSchedule();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Расписание обновлено'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
          print('SettingsPage: Группа не выбрана');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Группа не выбрана'),
            backgroundColor: Colors.orange,
          ),
        );
        }
      }
      
      setState(() => _isUpdating = false);
    } catch (e) {
      print('SettingsPage: Ошибка обновления: $e');
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка обновления: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Вы точно уверены?'),
        content: Text('Все данные будут потеряны'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Нет')),
          TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final appState = Provider.of<AppState>(context, listen: false);
                await appState.resetApp();
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }, 
              child: Text('Да')),
        ],
      ),
    );
  }
  
  void _changeGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Смена группы'),
        content: Text('Перейти к выбору новой группы?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            child: Text('Да'),
          ),
        ],
      ),
    );
  }
  

}
