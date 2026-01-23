import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/providers/app_state.dart';
import '../../data/services/notification_service.dart';
import '../../services/permissions_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_text.dart';

class StartScreen extends StatefulWidget {
  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  String? selectedForm;
  String? selectedCourse;
  String? selectedGroup;
  bool _permissionsRequested = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final permissionsGranted = await PermissionsService.requestSystemPermissions();
    setState(() {
      _permissionsRequested = true;
    });

    _checkExistingGroup();
  }

  Future<void> _checkExistingGroup() async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (await appState.hasSelectedGroup()) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      try {
        await appState.loadGroups();
      } catch (e) {
        print('Error in _checkExistingGroup: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (!_permissionsRequested) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppTheme.primaryText,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Подготовка приложения...',
                    style: GoogleFonts.inter(
                      fontSize: ResponsiveText.body(context),
                      color: AppTheme.primaryText,
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(15, 0, 15, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 100),
                Text(
                  'Добро пожаловать. Давайте настроим',
                  style: GoogleFonts.robotoCondensed(
                    fontSize: ResponsiveText.display(context),
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryText,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 30),
                _buildDropdown('Форма обучения...', selectedForm, appState.formEduOptions, _onFormChanged),
                SizedBox(height: 20),
                _buildDropdown('Курс', selectedCourse, appState.getCourseOptions(selectedForm), _onCourseChanged),
                SizedBox(height: 20),
                _buildDropdown('Группа', selectedGroup, appState.groups.map((g) => g.name).toList(), (v) => setState(() => selectedGroup = v)),
                Spacer(),
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 370,
                      minWidth: 200,
                    ),
                  child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedForm != null && selectedCourse != null && selectedGroup != null 
                            ? AppTheme.primaryText 
                            : Colors.grey,
                        foregroundColor: selectedForm != null && selectedCourse != null && selectedGroup != null 
                            ? Colors.yellow 
                            : Colors.white,
                      ),
                      onPressed: selectedForm != null && selectedCourse != null && selectedGroup != null ? _continue : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Продолжить'),
                          Icon(Icons.navigate_next),
                        ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdown(String hint, String? value, List<String> items,
      Function(String?) onChanged) {
    return Container(
      width: 250,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(hint, style: GoogleFonts.inter()),
        decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 12)),
        icon: Icon(Icons.keyboard_arrow_down),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _onFormChanged(String? value) {
    setState(() {
      selectedForm = value;
      selectedCourse = null;
      selectedGroup = null;
    });
  }

  void _onCourseChanged(String? value) {
    setState(() {
      selectedCourse = value;
      selectedGroup = null;
    });
    final appState = Provider.of<AppState>(context, listen: false);
    appState.filterGroups(selectedForm, selectedCourse);
  }

  void _continue() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final group = appState.groups.firstWhere((g) => g.name == selectedGroup);

      await appState.loadSchedule(group.id, group.name);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            appState.notifyScheduleLoaded();
          } catch (e) {
            // ignore
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
