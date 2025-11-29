class SemesterModel {
  final int id;
  final int? programId; // старое поле, может быть null
  final int? courseId; // новое поле
  final int semesterNumber;
  final String? name;

  SemesterModel({
    required this.id,
    this.programId,
    this.courseId,
    required this.semesterNumber,
    this.name,
  });

  factory SemesterModel.fromJson(Map<String, dynamic> json) {
    return SemesterModel(
      id: json['id'] as int,
      programId: json['program_id'] as int?,
      courseId: json['course_id'] as int?,
      semesterNumber: json['semester_number'] as int,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'program_id': programId,
    'course_id': courseId,
    'semester_number': semesterNumber,
    'name': name,
  };
}
