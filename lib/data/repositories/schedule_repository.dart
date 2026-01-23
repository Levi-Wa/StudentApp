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
    // Check if we have cached data and don't need update
    if (!forceUpdate && !await _localStorage.needsUpdate()) {
      final cachedSchedule = await _localStorage.getSchedule();
      if (cachedSchedule != null) {
        print('Using cached schedule');
        return cachedSchedule;
      }
    }

    // Try to get fresh data from API
    try {
      final hasInternet = await _apiService.hasInternetConnection();
      if (!hasInternet) {
        throw NetworkException('No internet connection');
      }
      
      final schedule = await _apiService.getSchedule(groupId);
      await _localStorage.saveSchedule(schedule);
      print('Schedule updated from server');
      return schedule;
    } catch (e) {
      // If network fails, try to use cached data
      final cachedSchedule = await _localStorage.getSchedule();
      if (cachedSchedule != null) {
        print('Using cached schedule due to network error: $e');
        return cachedSchedule;
      }
      // If no cache available, rethrow the error
      throw e;
    }
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
