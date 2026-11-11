class Department {
  final int id;
  final String name;
  final String shortName;

  Department({
    required this.id,
    required this.name,
    required this.shortName,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['Depart_ID'] is int
          ? json['Depart_ID'] as int
          : int.tryParse(json['Depart_ID'].toString()) ?? 0,
      name: json['DepartName']?.toString() ?? '',
      shortName: json['DepartSN']?.toString() ??
          json['DepartLN']?.toString() ??
          json['DepartName']?.toString() ??
          '',
    );
  }
}

class Teacher {
  final int empId;
  final int departId;
  final String fio;

  Teacher({
    required this.empId,
    required this.departId,
    required this.fio,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      empId: json['Emp_ID'] is int
          ? json['Emp_ID'] as int
          : int.tryParse(json['Emp_ID'].toString()) ?? 0,
      departId: json['Depart_ID'] is int
          ? json['Depart_ID'] as int
          : int.tryParse(json['Depart_ID'].toString()) ?? 0,
      fio: json['FIO']?.toString().trim() ?? '',
    );
  }
}

class TeacherLesson {
  final String time;
  final String subjName;
  final String subjShort;
  final String loadKind;
  final String empFio;
  final String groupName;
  final String aud;

  TeacherLesson({
    required this.time,
    required this.subjName,
    required this.subjShort,
    required this.loadKind,
    required this.empFio,
    required this.groupName,
    required this.aud,
  });

  factory TeacherLesson.fromJson(Map<String, dynamic> json) {
    return TeacherLesson(
      time: json['TimeStart']?.toString() ?? '',
      subjName: json['SubjName']?.toString() ?? '',
      subjShort: json['SubjSN']?.toString() ?? '',
      loadKind: json['LoadKindSN']?.toString() ?? '',
      empFio: json['EmpFIO']?.toString() ?? '',
      groupName: json['GSName']?.toString() ?? '',
      aud: json['Aud']?.toString() ?? '',
    );
  }
}

class TeacherDaySchedule {
  final String date;
  final String dayOfWeek;
  final String dayOfWeekShort;
  final List<TeacherLesson> lessons;

  TeacherDaySchedule({
    required this.date,
    required this.dayOfWeek,
    required this.dayOfWeekShort,
    required this.lessons,
  });
}
