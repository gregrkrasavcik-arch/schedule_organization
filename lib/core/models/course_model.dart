class CourseModel {
  final int id;
  final int programId;
  final int courseNumber;
  final String? name;

  CourseModel({
    required this.id,
    required this.programId,
    required this.courseNumber,
    this.name,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] as int,
      programId: json['program_id'] as int,
      courseNumber: json['course_number'] as int,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'program_id': programId,
    'course_number': courseNumber,
    'name': name,
  };
}
