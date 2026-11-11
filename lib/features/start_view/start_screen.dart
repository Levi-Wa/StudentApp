import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/providers/app_state.dart';
import '../../services/permissions_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_text.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  String? selectedForm;
  String? selectedCourse;
  String? selectedGroup;
  bool _permissionsRequested = false;
  bool _isCheckingGroup = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await PermissionsService.requestSystemPermissions();
    if (mounted) {
      setState(() {
        _permissionsRequested = true;
      });
    }

    _checkExistingGroup();
  }

  Future<void> _checkExistingGroup() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final hasGroup = await appState.hasSelectedGroup();
    if (hasGroup && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      try {
        await appState.loadGroups();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _isCheckingGroup = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionsRequested || _isCheckingGroup) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryAccent),
              const SizedBox(height: 20),
              Text(
                'Подготовка приложения...',
                style: GoogleFonts.inter(
                  fontSize: ResponsiveText.body(context),
                  color: AppTheme.primaryText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, appState, child) {
            final formOptions = appState.formEduOptions;
            final courseOptions = appState.getCourseOptions(selectedForm);
            final groupOptions = appState.groups.map((g) => g.name).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  // Welcome icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 44,
                      color: AppTheme.primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title & Subtitle
                  Text(
                    'Добро пожаловать!',
                    style: GoogleFonts.inter(
                      fontSize: ResponsiveText.headline(context),
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Выберите свою учебную группу, чтобы загрузить актуальное расписание',
                    style: GoogleFonts.inter(
                      fontSize: ResponsiveText.body(context),
                      color: AppTheme.secondaryText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // If failed to load groups
                  if (formOptions.isEmpty && !appState.isLoading) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.wifi_off_rounded,
                              color: Colors.red, size: 36),
                          const SizedBox(height: 8),
                          Text(
                            'Не удалось загрузить список групп',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Проверьте интернет-соединение и попробуйте снова',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryAccent,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => appState.loadGroups(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Повторить попытку'),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Form of education
                    _buildDropdown(
                      label: 'Форма обучения',
                      hint: 'Выберите форму обучения',
                      value: selectedForm,
                      items: formOptions,
                      onChanged: _onFormChanged,
                    ),
                    const SizedBox(height: 20),

                    // Course
                    _buildDropdown(
                      label: 'Курс',
                      hint: selectedForm == null
                          ? 'Сначала выберите форму'
                          : 'Выберите курс',
                      value: selectedCourse,
                      items: courseOptions,
                      onChanged: selectedForm != null ? _onCourseChanged : null,
                    ),
                    const SizedBox(height: 20),

                    // Group
                    _buildDropdown(
                      label: 'Группа',
                      hint: selectedCourse == null
                          ? 'Сначала выберите курс'
                          : 'Выберите группу',
                      value: selectedGroup,
                      items: groupOptions,
                      onChanged: (v) => setState(() => selectedGroup = v),
                    ),
                    const SizedBox(height: 40),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryAccent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppTheme.primaryAccent.withValues(alpha: 0.35),
                          disabledForegroundColor: Colors.white70,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: (_canContinue && !_isSubmitting)
                            ? _continue
                            : null,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Продолжить',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded,
                                      size: 20),
                                ],
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  bool get _canContinue =>
      selectedForm != null && selectedCourse != null && selectedGroup != null;

  Widget _buildDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.secondaryText,
            ),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.secondaryBackground,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.primaryAccent, width: 1.5),
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.primaryText,
                      ),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _onFormChanged(String? value) {
    setState(() {
      selectedForm = value;
      selectedCourse = null;
      selectedGroup = null;
    });
    if (value != null) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.filterGroups(value, null);
    }
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
    setState(() => _isSubmitting = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final group =
          appState.groups.firstWhere((g) => g.name == selectedGroup);

      await appState.loadSchedule(group.id, group.name, forceUpdate: true);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки расписания: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
