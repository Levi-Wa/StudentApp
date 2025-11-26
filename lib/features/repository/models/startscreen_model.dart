import 'package:studentApp/features/repository/models/schedule_model.dart';
import 'package:studentApp/features/repository/schedule_repository.dart';
import 'package:flutter/material.dart';
import 'package:studentApp/features/StartView/startScreenApp.dart';

class StartscreenModel extends ChangeNotifier {
  final ScheduleRepository _repository = ScheduleRepository();
  

  List<EducationForm> educationForms = [];
  bool isLoading = true;
  String? errorMessage;
  

  EducationForm? selectedForm;
  Course? selectedCourse;
  Group? selectedGroup;

  Future<void> loadEducationForms() async {
    try {
      final forms = await _repository.getAllGroups();
      educationForms = forms;
      isLoading = false;
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Ошибка загрузки данных: $e';
      isLoading = false;
    }
    notifyListeners();
  }


  void selectForm(EducationForm? form) {
    selectedForm = form;
    selectedCourse = null;
    selectedGroup = null;
    notifyListeners();
  }

 
  void selectCourse(Course? course) {
    selectedCourse = course;
    selectedGroup = null;
    notifyListeners();
  }


  void selectGroup(Group? group) {
    selectedGroup = group;
    notifyListeners();
  }


  List<Course> getCoursesForSelectedForm() {
    return selectedForm?.courses ?? [];
  }

  List<Group> getGroupsForSelectedCourse() {
    return selectedCourse?.groups ?? [];
  }

  Future<List<ScheduleMonth>> downloadSchedule() async {
    if (selectedGroup == null) throw Exception('Группа не выбрана');

    try {
      final groupId = selectedGroup!.id.toString();
      return await _repository.getSchedyleByGroupId(groupId);
    } catch (e) {
      throw Exception('Ошибка скачивания: $e');
    }
  }
}