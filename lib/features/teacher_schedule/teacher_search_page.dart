import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/teacher.dart';
import '../../data/services/teacher_service.dart';
import '../../theme/app_theme.dart';
import 'teacher_schedule_page.dart';

class TeacherSearchPage extends StatefulWidget {
  const TeacherSearchPage({super.key});

  @override
  State<TeacherSearchPage> createState() => _TeacherSearchPageState();
}

class _TeacherSearchPageState extends State<TeacherSearchPage> {
  final TeacherService _teacherService = TeacherService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;

  Department? _selectedDepartment;
  Teacher? _selectedTeacher;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _teacherService.loadTeachersData();
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_teacherService.departments.isNotEmpty) {
            _selectedDepartment = _teacherService.departments.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Не удалось загрузить список преподавателей: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<Teacher> _getFilteredTeachers() {
    if (_selectedDepartment == null) return [];
    var list = _teacherService.getTeachersByDepartment(_selectedDepartment!.id);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((t) => t.fio.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  void _openSchedule(Teacher teacher) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherSchedulePage(
          teacher: teacher,
          departmentName: _selectedDepartment?.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.bg(context);
    final cardBg = AppTheme.secondaryBg(context);
    final text = AppTheme.text(context);
    final subtext = AppTheme.subtext(context);
    final surface = AppTheme.surface(context);
    final divider = AppTheme.divider(context);

    final filteredTeachers = _getFilteredTeachers();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Поиск преподавателей',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: text,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.dockActiveAmber),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 14, color: text),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.dockActiveAmber,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: _loadData,
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Parameter 1: Department selector
                      Container(
                        padding: const EdgeInsets.all(16),
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
                                const Icon(Icons.apartment_rounded,
                                    size: 18, color: AppTheme.dockActiveAmber),
                                const SizedBox(width: 8),
                                Text(
                                  '1. Кафедра',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: text,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<Department>(
                              initialValue: _selectedDepartment,
                              isExpanded: true,
                              decoration: InputDecoration(
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
                              items: _teacherService.departments.map((dept) {
                                return DropdownMenuItem<Department>(
                                  value: dept,
                                  child: Text(
                                    dept.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      color: text,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (dept) {
                                setState(() {
                                  _selectedDepartment = dept;
                                  _selectedTeacher = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Parameter 2: Teacher search and selection
                      Container(
                        padding: const EdgeInsets.all(16),
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
                                const Icon(Icons.person_search_rounded,
                                    size: 18, color: AppTheme.dockActiveAmber),
                                const SizedBox(width: 8),
                                Text(
                                  '2. Преподаватель (${filteredTeachers.length})',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: text,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Быстрый поиск по ФИО...',
                                prefixIcon: Icon(Icons.search,
                                    size: 20, color: subtext),
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
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Teacher List
                      Expanded(
                        child: filteredTeachers.isEmpty
                            ? Center(
                                child: Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Преподаватель не найден'
                                      : 'В выбранной кафедре нет преподавателей',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: subtext,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredTeachers.length,
                                itemBuilder: (context, idx) {
                                  final teacher = filteredTeachers[idx];
                                  final isSelected =
                                      _selectedTeacher?.empId == teacher.empId;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.dockActiveAmber
                                              .withValues(alpha: 0.15)
                                          : cardBg,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.dockActiveAmber
                                            : divider,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 4),
                                      leading: CircleAvatar(
                                        backgroundColor: AppTheme.dockActiveAmber
                                            .withValues(alpha: 0.2),
                                        child: Text(
                                          teacher.fio.isNotEmpty
                                              ? teacher.fio[0]
                                              : '?',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.dockActiveAmber,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        teacher.fio,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: text,
                                        ),
                                      ),
                                      trailing: const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 16,
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _selectedTeacher = teacher;
                                        });
                                        _openSchedule(teacher);
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
