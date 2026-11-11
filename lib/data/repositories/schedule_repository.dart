import '../models/group.dart';
import '../models/full_schedule.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

class ScheduleRepository {
  final ApiService _apiService = ApiService();
  final LocalStorageService _localStorage = LocalStorageService();

  Future<List<Group>> getGroups() async {
    return await _apiService.getGroups();
  }

  Future<FullSchedule> getSchedule(int groupId,
      {bool forceUpdate = false}) async {
    // Если принудительное обновление не запрошено и кэш свежий — возвращаем кэш
    if (!forceUpdate && !await _localStorage.needsUpdate()) {
      final cachedSchedule = await _localStorage.getSchedule();
      if (cachedSchedule != null) {
        return cachedSchedule;
      }
    }

    // Загружаем свежие данные из API
    try {
      final schedule = await _apiService.getSchedule(groupId);
      await _localStorage.saveSchedule(schedule);
      return schedule;
    } catch (e) {
      // При сетевой ошибке пытаемся вернуть кэшированные данные
      final cachedSchedule = await _localStorage.getSchedule();
      if (cachedSchedule != null) {
        return cachedSchedule;
      }
      rethrow;
    }
  }

  Future<DateTime?> getLastUpdated() async {
    return await _localStorage.getLastUpdated();
  }

  Future<void> saveGroupSelection(int groupId, String groupName) async {
    await _localStorage.saveGroupInfo(groupId, groupName);
  }

  Future<int?> getSavedGroupId() async {
    return await _localStorage.getGroupId();
  }

  Future<String?> getSavedGroupName() async {
    return await _localStorage.getGroupName();
  }

  Future<void> clearAllData() async {
    await _localStorage.clearAll();
  }
}
