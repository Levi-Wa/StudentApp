import 'package:dio/dio.dart';
import 'dart:io';
import '../models/group.dart';
import '../models/full_schedule.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 10),
  ));

  Future<List<Group>> getGroups() async {
    try {
      final response = await _dio
          .get('https://api.ursei.su/public/schedule/rest/GetGSSchedIniData');

      if (response.data == null) {
        throw Exception('Пустой ответ от сервера');
      }

      final List<Group> allGroups = [];
      final formEduList = response.data['FormEdu'] as List;

      for (var formEdu in formEduList) {
        final formEduName = formEdu['FormEduName'];
        final cursArray = formEdu['arr'] as List;
        for (var curs in cursArray) {
          final courseNum = curs['Curs'];
          final groupsArray = curs['arr'] as List;
          for (var group in groupsArray) {
            allGroups.add(Group(
              id: group['GS_ID'],
              name: group['GSName'],
              formEdu: formEduName,
              course: courseNum,
            ));
          }
        }
      }

      return allGroups;
    } catch (e) {
      print('Detailed error: $e');
      throw Exception('Ошибка загрузки групп: $e');
    }
  }

  Future<FullSchedule> getSchedule(int groupId) async {
    print('ApiService: === НАЧАЛО ЗАГРУЗКИ РАСПИСАНИЯ ===');
    try {
      print('ApiService: Загружаю расписание для группы ID: $groupId');
      final url = 'https://api.ursei.su/public/schedule/rest/GetGsSched?grpid=$groupId';
      print('ApiService: URL запроса: $url');

      final response = await _dio.get(url);
      print('ApiService: Получен ответ от сервера, статус: ${response.statusCode}');
      
      if (response.data == null) {
        print('ApiService: ОШИБКА - пустой ответ от сервера');
        throw Exception('Нет данных о расписании');
      }
      
      print('ApiService: Парсинг данных расписания...');
      final schedule = FullSchedule.fromJson(response.data);
      print('ApiService: Расписание успешно распарсено, найдено дней: ${schedule.days.length}');

      for (var day in schedule.days) {
        print('  - ${day.dayOfWeek} (${day.date}): ${day.lessons.length} занятий');
      }

      print('ApiService: === ЗАГРУЗКА РАСПИСАНИЯ ЗАВЕРШЕНА ===');
      return schedule;
    } on DioException catch (e) {
      print('ApiService: DioException: ${e.type} - ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Нет подключения к интернету');
      }
      print('ApiService: Ошибка загрузки расписания: $e');
      throw Exception('Ошибка загрузки расписания: $e');
    } catch (e) {
      print('ApiService: Неожиданная ошибка: $e');
      throw Exception('Ошибка загрузки расписания: $e');
    }
  }

  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  
  @override
  String toString() => message;
}
