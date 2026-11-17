import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/models/teacher.dart';
import '../../data/providers/app_state.dart';
import '../../data/services/teacher_service.dart';
import '../../services/permissions_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_text.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  // Role: 'student' or 'teacher'
  String _selectedRole = 'student';

  // Student selections
  String? selectedForm;
  String? selectedCourse;
  String? selectedGroup;

  // Teacher selections
  final TeacherService _teacherService = TeacherService();
  Department? _selectedDepartment;
  Teacher? _selectedTeacher;
  String _teacherSearchQuery = '';
  final TextEditingController _teacherSearchController = TextEditingController();

  bool _permissionsRequested = false;
  bool _isCheckingProfile = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _teacherSearchController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await PermissionsService.requestSystemPermissions();
    if (mounted) {
      setState(() {
        _permissionsRequested = true;
      });
    }

    _checkExistingProfile();
  }

  Future<void> _checkExistingProfile() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final hasProfile = await appState.hasSelectedProfile();
    if (hasProfile && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      try {
        await appState.loadGroups();
      } catch (_) {}
      try {
        await _teacherService.loadTeachersData();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isCheckingProfile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionsRequested || _isCheckingProfile) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.dockActiveAmber),
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
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Welcome icon
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.dockActiveAmber.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _selectedRole == 'student'
                          ? Icons.school_rounded
                          : Icons.workspace_premium_rounded,
                      size: 40,
                      color: AppTheme.dockActiveAmber,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Title & Subtitle
                  Text(
                    'Добро пожаловать!',
                    style: GoogleFonts.inter(
                      fontSize: ResponsiveText.headline(context),
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Выберите свой профиль, чтобы загрузить актуальное расписание',
                    style: GoogleFonts.inter(
                      fontSize: ResponsiveText.body(context),
                      color: AppTheme.secondaryText,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Role selector: [ Для студента | Для преподавателя ]
                  Container(
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => setState(() => _selectedRole = 'student'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                color: _selectedRole == 'student'
                                    ? AppTheme.dockActiveAmber
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.school_rounded,
                                    size: 16,
                                    color: _selectedRole == 'student'
                                        ? Colors.black
                                        : AppTheme.secondaryText,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Для студента',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: _selectedRole == 'student'
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: _selectedRole == 'student'
                                          ? Colors.black
                                          : AppTheme.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => setState(() => _selectedRole = 'teacher'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                color: _selectedRole == 'teacher'
                                    ? AppTheme.dockActiveAmber
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_outline_rounded,
                                    size: 16,
                                    color: _selectedRole == 'teacher'
                                        ? Colors.black
                                        : AppTheme.secondaryText,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Для преподавателя',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: _selectedRole == 'teacher'
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: _selectedRole == 'teacher'
                                          ? Colors.black
                                          : AppTheme.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Forms depending on selected role
                  if (_selectedRole == 'student')
                    _buildStudentForm(appState)
                  else
                    _buildTeacherForm(),

                  const SizedBox(height: 32),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dockActiveAmber,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor:
                            AppTheme.dockActiveAmber.withValues(alpha: 0.35),
                        disabledForegroundColor: Colors.black45,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
                                color: Colors.black,
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
                                const Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ==================== STUDENT FORM ====================
  Widget _buildStudentForm(AppState appState) {
    final formOptions = appState.formEduOptions;
    final courseOptions = appState.getCourseOptions(selectedForm);
    final groupOptions = appState.groups.map((g) => g.name).toList();

    if (formOptions.isEmpty && !appState.isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.red, size: 36),
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
                backgroundColor: AppTheme.dockActiveAmber,
                foregroundColor: Colors.black,
              ),
              onPressed: () => appState.loadGroups(),
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить попытку'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Form of education
        _buildDropdown(
          label: 'Форма обучения',
          hint: 'Выберите форму обучения',
          value: selectedForm,
          items: formOptions,
          onChanged: _onFormChanged,
        ),
        const SizedBox(height: 18),

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
        const SizedBox(height: 18),

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
      ],
    );
  }

  // ==================== TEACHER FORM ====================
  Widget _buildTeacherForm() {
    final cardBg = AppTheme.secondaryBackground;
    final surface = AppTheme.surface(context);
    final text = AppTheme.primaryText;
    final subtext = AppTheme.secondaryText;
    final divider = AppTheme.dividerColor;

    List<Teacher> teachers = [];
    if (_selectedDepartment != null) {
      teachers = _teacherService.getTeachersByDepartment(_selectedDepartment!.id);
      if (_teacherSearchQuery.trim().isNotEmpty) {
        final q = _teacherSearchQuery.trim().toLowerCase();
        teachers = teachers.where((t) => t.fio.toLowerCase().contains(q)).toList();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Select Department
        Text(
          '1. Кафедра',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: text,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showDepartmentBottomSheet(
            context,
            cardBg,
            surface,
            text,
            subtext,
            divider,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDepartment?.name ?? 'Выберите кафедру',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _selectedDepartment != null ? text : subtext,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: subtext),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // 2. Select Teacher
        if (_selectedDepartment != null) ...[
          Text(
            '2. Преподаватель (ФИО)',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
          const SizedBox(height: 8),

          // Search field
          TextField(
            controller: _teacherSearchController,
            style: GoogleFonts.inter(fontSize: 14, color: text),
            decoration: InputDecoration(
              hintText: 'Поиск по фамилии...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: subtext),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              filled: true,
              fillColor: surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: divider),
              ),
            ),
            onChanged: (v) => setState(() => _teacherSearchQuery = v),
          ),
          const SizedBox(height: 10),

          // Teacher selection list
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: divider),
            ),
            child: teachers.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Преподаватели не найдены',
                        style: GoogleFonts.inter(fontSize: 13, color: subtext),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: teachers.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: divider),
                    itemBuilder: (context, index) {
                      final t = teachers[index];
                      final isSelected = _selectedTeacher?.empId == t.empId;

                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: isSelected
                              ? AppTheme.dockActiveAmber
                              : AppTheme.dockActiveAmber.withValues(alpha: 0.15),
                          child: Text(
                            t.fio.isNotEmpty ? t.fio[0] : '?',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.black : AppTheme.dockActiveAmber,
                            ),
                          ),
                        ),
                        title: Text(
                          t.fio,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppTheme.dockActiveAmber : text,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                color: AppTheme.dockActiveAmber, size: 18)
                            : null,
                        onTap: () => setState(() => _selectedTeacher = t),
                      );
                    },
                  ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: divider),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 20, color: subtext),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Сначала выберите кафедру, чтобы увидеть список преподавателей',
                    style: GoogleFonts.inter(fontSize: 12.5, color: subtext),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showDepartmentBottomSheet(
    BuildContext context,
    Color cardBg,
    Color surface,
    Color text,
    Color subtext,
    Color divider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final departs = _teacherService.departments;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: subtext.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.apartment_rounded,
                        color: AppTheme.dockActiveAmber, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Выберите кафедру',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: departs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final dept = departs[index];
                      final isSelected = _selectedDepartment?.id == dept.id;

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          setState(() {
                            _selectedDepartment = dept;
                            _selectedTeacher = null;
                            _teacherSearchQuery = '';
                            _teacherSearchController.clear();
                          });
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.dockActiveAmber.withValues(alpha: 0.12)
                                : surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.dockActiveAmber
                                  : divider,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  dept.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppTheme.dockActiveAmber
                                        : text,
                                  ),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.dockActiveAmber,
                                  size: 20,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool get _canContinue {
    if (_selectedRole == 'student') {
      return selectedForm != null &&
          selectedCourse != null &&
          selectedGroup != null;
    } else {
      return _selectedTeacher != null;
    }
  }

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
                  const BorderSide(color: AppTheme.dockActiveAmber, width: 1.5),
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

      if (_selectedRole == 'student') {
        final group =
            appState.groups.firstWhere((g) => g.name == selectedGroup);
        await appState.setUserRole('student');
        await appState.loadSchedule(group.id, group.name, forceUpdate: true);
      } else {
        // Teacher
        if (_selectedTeacher != null) {
          await appState.saveTeacherSelection(
            empId: _selectedTeacher!.empId,
            departId: _selectedTeacher!.departId,
            fio: _selectedTeacher!.fio,
            departName: _selectedDepartment?.name,
          );
        }
      }

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
