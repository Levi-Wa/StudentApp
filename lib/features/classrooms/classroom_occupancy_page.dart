import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/models/classroom_occupancy.dart';
import '../../data/providers/app_state.dart';
import '../../data/services/classroom_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_text.dart';

class ClassroomOccupancyPage extends StatefulWidget {
  final DateTime? initialDate;

  const ClassroomOccupancyPage({super.key, this.initialDate});

  @override
  State<ClassroomOccupancyPage> createState() => _ClassroomOccupancyPageState();
}

class _ClassroomOccupancyPageState extends State<ClassroomOccupancyPage> {
  final ClassroomService _service = ClassroomService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isOccupancyLoading = false;
  String? _error;
  ClassroomOccupancyData? _data;

  late DateTime _selectedDate;
  ClassroomPair? _selectedPair;
  int _selectedBuildingIndex = 0;
  String _statusFilter = 'all'; // 'all', 'free', 'busy'
  String _searchQuery = '';

  List<RoomStatus> _allStatuses = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int? _parseTimeToMinutes(String timeStr) {
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          return h * 60 + m;
        }
      }
    } catch (_) {}
    return null;
  }

  bool _isPairCurrent(ClassroomPair p) {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    if (!isToday) return false;

    final cur = now.hour * 60 + now.minute;
    final s = _parseTimeToMinutes(p.timeStart);
    final e = _parseTimeToMinutes(p.timeEnd);
    if (s == null || e == null || s >= e) return false;

    return cur >= s && cur <= e;
  }

  ClassroomPair _findCurrentPair(List<ClassroomPair> pairs) {
    if (pairs.isEmpty) {
      return ClassroomPair(
        pairId: 0,
        pairNumb: 1,
        timeStart: '08:30',
        timeEnd: '10:05',
      );
    }

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    // Filter out pairs that have zero or invalid times
    final validPairs = pairs.where((p) {
      final s = _parseTimeToMinutes(p.timeStart);
      final e = _parseTimeToMinutes(p.timeEnd);
      return s != null && e != null && s < e;
    }).toList();

    if (validPairs.isEmpty) return pairs.first;

    // 1. Check if current time is inside a pair
    for (final p in validPairs) {
      final s = _parseTimeToMinutes(p.timeStart)!;
      final e = _parseTimeToMinutes(p.timeEnd)!;
      if (currentMinutes >= s && currentMinutes <= e) {
        return p;
      }
    }

    // 2. Check if in a break or before an upcoming pair today
    for (final p in validPairs) {
      final s = _parseTimeToMinutes(p.timeStart)!;
      if (currentMinutes < s) {
        return p; // Next upcoming pair
      }
    }

    // 3. If after all pairs today, return the first pair
    return validPairs.first;
  }

  Future<void> _loadData({bool forceReload = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _service.loadClassroomData(forceReload: forceReload);
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;

          if (data.pairs.isNotEmpty) {
            _selectedPair = _findCurrentPair(data.pairs);
          }
        });

        await _loadOccupancy(forceReload: forceReload);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Не удалось загрузить данные об аудиториях: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadOccupancy({bool forceReload = false}) async {
    if (_data == null || _data!.buildings.isEmpty || _selectedPair == null) {
      return;
    }

    setState(() {
      _isOccupancyLoading = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final building =
          _data!.buildings[_selectedBuildingIndex.clamp(0, _data!.buildings.length - 1)];

      final statuses = await _service.fetchGlobalOccupancy(
        building: building,
        date: _selectedDate,
        pair: _selectedPair!,
        fallbackSchedule: appState.schedule,
        forceReload: forceReload,
      );

      if (mounted) {
        setState(() {
          _allStatuses = statuses;
          _isOccupancyLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isOccupancyLoading = false;
        });
      }
    }
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 90)),
      locale: const Locale('ru', 'RU'),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        if (_data != null && _data!.pairs.isNotEmpty) {
          final isToday = picked.year == now.year &&
              picked.month == now.month &&
              picked.day == now.day;
          if (isToday) {
            _selectedPair = _findCurrentPair(_data!.pairs);
          }
        }
      });
      await _loadOccupancy();
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showRoomDetails(RoomStatus room) {
    final cardBg = AppTheme.secondaryBg(context);
    final text = AppTheme.text(context);
    final subtext = AppTheme.subtext(context);
    final surface = AppTheme.surface(context);
    final divider = AppTheme.divider(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isBusy = room.isBusy;
        final subj = room.displaySubject;
        final teacher = room.displayTeacher;
        final grp = room.displayGroup;
        final type = room.displayType;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
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

                // Room header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isBusy
                            ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                            : const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isBusy
                            ? Icons.meeting_room_rounded
                            : Icons.door_front_door_rounded,
                        color: isBusy
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Аудитория ${room.classroom.audName}',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: text,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            room.classroom.audTypeName.isNotEmpty
                                ? room.classroom.audTypeName
                                : 'Учебная аудитория',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: subtext,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isBusy
                            ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                            : const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isBusy
                              ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                              : const Color(0xFF10B981).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        isBusy ? 'ЗАНЯТА' : 'СВОБОДНА',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isBusy
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Info grid
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: divider),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        Icons.people_outline_rounded,
                        'Вместимость',
                        '${room.classroom.volume} мест',
                        text,
                        subtext,
                      ),
                      const Divider(height: 20),
                      _buildInfoRow(
                        Icons.access_time_rounded,
                        'Выбранная пара',
                        _selectedPair != null
                            ? '${_selectedPair!.pairNumb}-я пара (${_selectedPair!.timeFormatted})'
                            : 'Не выбрана',
                        text,
                        subtext,
                      ),
                      if (isBusy) ...[
                        if (subj != null && subj.isNotEmpty) ...[
                          const Divider(height: 20),
                          _buildInfoRow(
                            Icons.menu_book_rounded,
                            'Предмет',
                            subj,
                            text,
                            subtext,
                          ),
                        ],
                        if (grp != null && grp.isNotEmpty) ...[
                          const Divider(height: 20),
                          _buildInfoRow(
                            Icons.group_rounded,
                            'Группа',
                            grp,
                            text,
                            subtext,
                          ),
                        ],
                        if (teacher != null && teacher.isNotEmpty) ...[
                          const Divider(height: 20),
                          _buildInfoRow(
                            Icons.person_rounded,
                            'Преподаватель',
                            teacher,
                            text,
                            subtext,
                          ),
                        ],
                        if (type != null && type.isNotEmpty) ...[
                          const Divider(height: 20),
                          _buildInfoRow(
                            Icons.category_rounded,
                            'Тип занятия',
                            type,
                            text,
                            subtext,
                          ),
                        ],
                      ] else ...[
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                size: 18, color: Color(0xFF10B981)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Аудитория свободна для занятий и подготовки',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.dockActiveAmber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Закрыть',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color text,
    Color subtext,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.dockActiveAmber),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: subtext,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
        ),
      ],
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

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Занятость аудиторий',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: text,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Обновить данные',
            icon: Icon(Icons.refresh_rounded, color: text),
            onPressed: () => _loadOccupancy(forceReload: true),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.dockActiveAmber),
                  SizedBox(height: 16),
                  Text('Загрузка аудиторного фонда...'),
                ],
              ),
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
                          onPressed: () => _loadData(forceReload: true),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildContent(cardBg, text, subtext, surface, divider),
    );
  }

  Widget _buildContent(
    Color cardBg,
    Color text,
    Color subtext,
    Color surface,
    Color divider,
  ) {
    if (_data == null || _data!.buildings.isEmpty) {
      return Center(
        child: Text('Нет данных об аудиториях', style: TextStyle(color: text)),
      );
    }

    final buildings = _data!.buildings;
    final currentBuilding =
        buildings[_selectedBuildingIndex.clamp(0, buildings.length - 1)];

    // Filter statuses
    List<RoomStatus> filteredStatuses = _allStatuses;
    if (filteredStatuses.isEmpty && !_isOccupancyLoading) {
      filteredStatuses = currentBuilding.auds
          .map((a) => RoomStatus(classroom: a, isBusy: false))
          .toList();
    }

    if (_statusFilter == 'free') {
      filteredStatuses = filteredStatuses.where((r) => !r.isBusy).toList();
    } else if (_statusFilter == 'busy') {
      filteredStatuses = filteredStatuses.where((r) => r.isBusy).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filteredStatuses = filteredStatuses.where((r) {
        return r.classroom.audName.toLowerCase().contains(q) ||
            r.classroom.audTypeName.toLowerCase().contains(q) ||
            (r.displaySubject?.toLowerCase().contains(q) ?? false) ||
            (r.displayTeacher?.toLowerCase().contains(q) ?? false) ||
            (r.displayGroup?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    final int totalCount = currentBuilding.auds.length;
    final int busyCount =
        _allStatuses.where((r) => r.isBusy).length;
    final int freeCount = totalCount - busyCount;

    return Column(
      children: [
        // Top Filter Bar: Date and Pair selectors
        Container(
          color: cardBg,
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Column(
            children: [
              // 1. Date selector row
              Row(
                children: [
                  // Pick Date pill
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: divider),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 15,
                              color: AppTheme.dockActiveAmber,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatDate(_selectedDate),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down_rounded,
                                size: 18, color: subtext),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Today button
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final now = DateTime.now();
                      setState(() {
                        _selectedDate = now;
                        if (_data != null && _data!.pairs.isNotEmpty) {
                          _selectedPair = _findCurrentPair(_data!.pairs);
                        }
                      });
                      await _loadOccupancy();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: divider),
                      ),
                      child: Text(
                        'Сегодня',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: text,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 2. Pairs horizontal selector
              if (_data!.pairs.isNotEmpty)
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _data!.pairs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final pair = _data!.pairs[index];
                      final isSelected = _selectedPair?.pairId == pair.pairId;
                      final isNow = _isPairCurrent(pair);

                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          setState(() {
                            _selectedPair = pair;
                          });
                          await _loadOccupancy();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.dockActiveAmber
                                : surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.dockActiveAmber
                                  : isNow
                                      ? Colors.orange.withValues(alpha: 0.6)
                                      : divider,
                              width: isNow ? 1.5 : 1.0,
                            ),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isNow) ...[
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(right: 5),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                                Text(
                                  '${pair.pairNumb}-я пара (${pair.timeStart})',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected ? Colors.black : text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        // Building segmented tabs
        if (buildings.length > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: buildings.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final b = buildings[index];
                  final isSelected = _selectedBuildingIndex == index;

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      setState(() {
                        _selectedBuildingIndex = index;
                      });
                      await _loadOccupancy();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.dockActiveAmber.withValues(alpha: 0.15)
                            : surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.dockActiveAmber
                              : divider,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          b.buildingName,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppTheme.dockActiveAmber
                                : text,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

        // Search & Status filters
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
          child: Row(
            children: [
              // Search input
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(fontSize: 13, color: text),
                    decoration: InputDecoration(
                      hintText: 'Поиск (ауд, группа, препод)...',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 12, color: subtext),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      filled: true,
                      fillColor: surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: divider),
                      ),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Filter chips (All / Free / Busy)
              _buildStatusChip('all', 'Все ($totalCount)', text, subtext, surface, divider),
              const SizedBox(width: 4),
              _buildStatusChip('free', '🟢 $freeCount', text, subtext, surface, divider),
              const SizedBox(width: 4),
              _buildStatusChip('busy', '🔴 $busyCount', text, subtext, surface, divider),
            ],
          ),
        ),

        if (_isOccupancyLoading)
          const LinearProgressIndicator(
            color: AppTheme.dockActiveAmber,
            backgroundColor: Colors.transparent,
            minHeight: 2,
          ),

        Divider(height: 1, color: divider),

        // Classrooms Grid
        Expanded(
          child: filteredStatuses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: subtext),
                      const SizedBox(height: 12),
                      Text(
                        'Аудитории не найдены',
                        style: GoogleFonts.inter(
                          fontSize: ResponsiveText.title(context),
                          fontWeight: FontWeight.w700,
                          color: text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Попробуйте изменить параметры поиска или фильтр',
                        style: GoogleFonts.inter(
                          fontSize: ResponsiveText.body(context),
                          color: subtext,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: filteredStatuses.length,
                  itemBuilder: (context, index) {
                    final room = filteredStatuses[index];
                    final isBusy = room.isBusy;
                    final subj = room.displaySubject;
                    final grp = room.displayGroup;
                    final teacher = room.displayTeacher;

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showRoomDetails(room),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isBusy
                                ? const Color(0xFFEF4444).withValues(alpha: 0.35)
                                : const Color(0xFF10B981).withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Aud name + Status badge
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    room.classroom.audName,
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: text,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isBusy
                                        ? const Color(0xFFEF4444)
                                            .withValues(alpha: 0.15)
                                        : const Color(0xFF10B981)
                                            .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isBusy ? 'Занята' : 'Свободна',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isBusy
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),

                            // Type and volume
                            Text(
                              room.classroom.audTypeName.isNotEmpty
                                  ? room.classroom.audTypeName
                                  : 'Учебная ауд.',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: subtext,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const Spacer(),

                            // If busy: group & subject info; if free: capacity
                            if (isBusy) ...[
                              if (grp != null && grp.isNotEmpty) ...[
                                Text(
                                  grp,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.dockActiveAmber,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              Text(
                                subj ?? teacher ?? 'Занятие',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Icon(Icons.people_outline_rounded,
                                      size: 13, color: subtext),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${room.classroom.volume} мест',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: subtext,
                                    ),
                                  ),
                                ],
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
    );
  }

  Widget _buildStatusChip(
    String filter,
    String label,
    Color text,
    Color subtext,
    Color surface,
    Color divider,
  ) {
    final isSelected = _statusFilter == filter;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _statusFilter = filter),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.dockActiveAmber.withValues(alpha: 0.15)
              : surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.dockActiveAmber : divider,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.dockActiveAmber : text,
          ),
        ),
      ),
    );
  }
}
