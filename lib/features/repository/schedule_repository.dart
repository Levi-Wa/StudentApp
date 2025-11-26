import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:path_provider/path_provider.dart';
import 'package:studentApp/features/repository/models/schedule_model.dart';
import 'package:dio/dio.dart';


class  ScheduleRepository {
  final _dio = Dio();

  Future<List<EducationForm>> getAllGroups() async {
    try {
      final response = await _dio.get(
        'https://api.ursei.su/public/schedule/rest/GetGSSchedIniData',
      );

      final List<dynamic> formEduList = response.data['FormEdu'];
      return formEduList
        .map((json) => EducationForm.fromJson(json))
        .toList();
    } catch (e) {
      throw Exception('Не скачал список групп $e');
    }
  }
  Future<List<ScheduleMonth>> getSchedyleByGroupId(String groupId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/schedule_$groupId.json'; 
      await _dio.download(
      'https://api.ursei.su/public/schedule/rest/GetGsSched?grpid=$groupId', filePath,
    );
    
    final file = File(filePath);
    final jsonString = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(jsonString);
    final List<dynamic> monthJson = data['Month'];
  
    return monthJson.map((json) => ScheduleMonth.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Не скачал расписание для групы $groupId: $e');
    }
    
  } 
}

