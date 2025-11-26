// class SheduleModelPair {

//   final String dataPair;
//   final String dayWeekShort;
//   final Map mainSchedule;

//   const SheduleModelPair({
//     required this.dataPair,
//     required this.dayWeekShort,
//     required this.mainSchedule,

//   }); 

//   factory SheduleModelPair.fromJson(Map<String, dynamic> json) {
//     return SheduleModelPair(dataPair: json['datePair'] as String,
//     dayWeekShort: json['dayWakeShort'] as String, 
//     mainSchedule: json['mainSchedule'] as Map<String, dynamic>
//     );
//   }
// }

// class SheduleModelGrupp {

//   final Map formEduName;
//   final List curs;
//   final Map mapGrupp;

//   const SheduleModelGrupp({
//     required this.formEduName,
//     required this.curs,
//     required this.mapGrupp,
//   });

//   factory SheduleModelGrupp.fromJson(Map<String, dynamic> json) {
//     return SheduleModelGrupp(
//       formEduName: json['FormEduName'] as Map<String, dynamic>,
//       curs: json['Curs'] as List<dynamic>,
//       mapGrupp: json['MapGr']
//       )
//   }

// }

class Group {
  final int id;        
  final String name;   

  const Group({required this.id, required this.name});

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['GS_ID'] as int,
      name: json['GSName'] as String,
    );
  }
}

class Course {
  final int number;          
  final List<Group> groups;   

  const Course({required this.number, required this.groups});

  factory Course.fromJson(Map<String, dynamic> json) {
    var list = json['arr'] as List<dynamic>;
    return Course(
      number: json['Curs'] as int,
      groups: list.map((e) => Group.fromJson(e)).toList(),
    );
  }
}

// Форма обучения (Очная, Заочная)
class EducationForm {
  final int id;
  final String name;         
  final List<Course> courses;

  const EducationForm({
    required this.id,
    required this.name,
    required this.courses,
  });

  factory EducationForm.fromJson(Map<String, dynamic> json) {
    var list = json['arr'] as List<dynamic>;
    return EducationForm(
      id: json['FormEdu_ID'] as int,
      name: json['FormEduName'] as String,
      courses: list.map((e) => Course.fromJson(e)).toList(),
    );
  }
}

class Lesson {
  final String timeStart;
  final String subjectName;
  final String subjectShort;
  final String lessonType;
  final String teacher;
  final String room;

 const Lesson({
  required  this.timeStart, 
  required  this.subjectName, 
  required  this.subjectShort, 
  required  this.lessonType, 
  required  this.teacher, 
  required  this.room,
});
  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      timeStart: json['TimeStart'] as String? ?? '', 
      subjectName: json['SubjName'] as String? ?? '-', 
      subjectShort: json['SubjSN'] as String? ?? '', 
      lessonType: json['LoadKindSN'] as String? ?? json['LoadKind'] as String? ?? '', 
      teacher:json['FIO'] as String? ?? '-', 
      room:json['Aud'] as String? ?? '-'
      );
  }
}

class ScheduleDay {
  final String data;
  final String dayOfWeek;
  final String dayShort;
  final List<Lesson> lessons;

  ScheduleDay({
    required this.data, 
    required this.dayOfWeek, 
    required this.dayShort, 
    required this.lessons
    });
  factory ScheduleDay.fromJson(Map<String, dynamic> json) {
    final lessonJson = json['mapSchedule'] as List<dynamic>? ?? [];
    return ScheduleDay(
      data: json['dataPair'] as String? ?? '', 
      dayOfWeek: json['dayWeek'] as String? ??'', 
      dayShort: json['dayWeekShort'] as String? ??'', 
      lessons: lessonJson.map((e) => Lesson.fromJson(e)).toList(),
      );
  }
}

class ScheduleMonth {
  final String name;
  final int number;
  final List<ScheduleDay> days;

  ScheduleMonth({
    required this.name, 
    required this.number, 
    required this.days

    });

  factory ScheduleMonth.fromJson(Map<String, dynamic> json) {
    final schedJson = json['Sched'] as List<dynamic>? ?? [];
    return ScheduleMonth(
      name: json['Name'] as String? ??'', 
      number: json['Numb'] as int? ?? 0, 
      days: schedJson.map((e) => ScheduleDay.fromJson(e)).toList(),
      );
  }
}