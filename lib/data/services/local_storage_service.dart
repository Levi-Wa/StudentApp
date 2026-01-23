import 'package:hive/hive.dart';
import '../models/full_schedule.dart';

class LocalStorageService {
  static const String _scheduleBox = 'schedule';
  static const String _settingsBox = 'settings';

  Future<void> saveSchedule(FullSchedule schedule) async {
    print('LocalStorage: Начинаю сохранение расписания...');
    try {
    final box = await Hive.openBox<FullSchedule>(_scheduleBox);
      print('LocalStorage: Box открыт, сохраняю расписание...');
    await box.put('current_schedule', schedule);
      print('LocalStorage: Расписание сохранено успешно');
      await box.close();
      print('LocalStorage: Box закрыт');
    } catch (e) {
      print('LocalStorage: Ошибка сохранения расписания: $e');
      throw e;
    }
  }

  Future<FullSchedule?> getSchedule() async {
    print('LocalStorage: Получаю кэшированное расписание...');
    try {
    final box = await Hive.openBox<FullSchedule>(_scheduleBox);
      final schedule = box.get('current_schedule');
      print('LocalStorage: Расписание получено из кэша: ${schedule != null ? "есть" : "нет"}');
      await box.close();
      return schedule;
    } catch (e) {
      print('LocalStorage: Ошибка получения расписания: $e');
      throw e;
    }
  }

  Future<void> saveGroupInfo(int groupId, String groupName) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('group_id', groupId);
    await box.put('group_name', groupName);
  }

  Future<int?> getGroupId() async {
    final box = await Hive.openBox(_settingsBox);
    return box.get('group_id');
  }

  Future<String?> getGroupName() async {
    final box = await Hive.openBox(_settingsBox);
    return box.get('group_name');
  }

  Future<bool> needsUpdate() async {
    final schedule = await getSchedule();
    if (schedule == null) return true;

    final now = DateTime.now();
    final lastUpdate = schedule.lastUpdated;
    
    // Check if it's a new day (daily update)
    final isSameDay = now.year == lastUpdate.year &&
                     now.month == lastUpdate.month &&
                     now.day == lastUpdate.day;
    
    return !isSameDay;
  }
  
  Future<void> clearAll() async {
    final scheduleBox = await Hive.openBox<FullSchedule>(_scheduleBox);
    final settingsBox = await Hive.openBox(_settingsBox);
    
    await scheduleBox.clear();
    await settingsBox.clear();
  }
}
