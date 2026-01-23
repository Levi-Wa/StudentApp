class Group {
  final int id;
  final String name;
  final String formEdu;
  final int course;

  Group({
    required this.id,
    required this.name,
    required this.formEdu,
    required this.course,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      formEdu: json['formEdu'] ?? '',
      course: json['course'] ?? 1,
    );
  }
}
