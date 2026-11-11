import 'package:hive/hive.dart';
import '../models/full_schedule.dart';

class LocalStorageService {
  static const String _scheduleBox = 'schedule';
  static const String _settingsBox = 'settings';

  Future<Box<FullSchedule>> _getScheduleBox() async {
    if (Hive.isBoxOpen(_scheduleBox)) {
      return Hive.box<FullSchedule>(_scheduleBox);
    }
    return await Hive.openBox<FullSchedule>(_scheduleBox);
  }

  Future<Box> _getSettingsBox() async {
    if (Hive.isBoxOpen(_settingsBox)) {
      return Hive.box(_settingsBox);
    }
    return await Hive.openBox(_settingsBox);
  }

  Future<void> saveSchedule(FullSchedule schedule) async {
    try {
      final box = await _getScheduleBox();
      await box.put('current_schedule', schedule);
    } catch (e) {
      // Reopen box if it was corrupted/closed
      final box = await Hive.openBox<FullSchedule>(_scheduleBox);
      await box.put('current_schedule', schedule);
    }
  }

  Future<FullSchedule?> getSchedule() async {
    try {
      final box = await _getScheduleBox();
      return box.get('current_schedule');
    } catch (e) {
      try {
        final box = await Hive.openBox<FullSchedule>(_scheduleBox);
        return box.get('current_schedule');
      } catch (_) {
        return null;
      }
    }
  }

  Future<DateTime?> getLastUpdated() async {
    final schedule = await getSchedule();
    return schedule?.lastUpdated;
  }

  Future<void> saveGroupInfo(int groupId, String groupName) async {
    final box = await _getSettingsBox();
    await box.put('group_id', groupId);
    await box.put('group_name', groupName);
  }

  Future<int?> getGroupId() async {
    final box = await _getSettingsBox();
    return box.get('group_id');
  }

  Future<String?> getGroupName() async {
    final box = await _getSettingsBox();
    return box.get('group_name');
  }

  /// Проверяет, требуется ли обновление кэша.
  /// Расписание считается устаревшим, если:
  /// 1. Кэша нет
  /// 2. Наступил новый день
  /// 3. С момента последнего обновления прошло более [maxAge] (по умолчанию 3 часа)
  Future<bool> needsUpdate({Duration maxAge = const Duration(hours: 3)}) async {
    final schedule = await getSchedule();
    if (schedule == null) return true;

    final now = DateTime.now();
    final lastUpdate = schedule.lastUpdated;

    // Проверяем смену календарного дня
    final isSameDay = now.year == lastUpdate.year &&
        now.month == lastUpdate.month &&
        now.day == lastUpdate.day;

    if (!isSameDay) return true;

    // Проверяем давность кэша в течение дня
    final age = now.difference(lastUpdate);
    return age > maxAge;
  }

  Future<void> clearAll() async {
    final scheduleBox = await _getScheduleBox();
    final settingsBox = await _getSettingsBox();

    await scheduleBox.clear();
    await settingsBox.clear();
  }
}
