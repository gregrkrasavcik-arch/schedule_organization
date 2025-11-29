class GroupModel {
  final int id;
  final String name;
  final String? specialization;
  final int yearStarted;
  final int? programId;
  final int? courseId;
  final String status; // active, graduated, archived
  final DateTime? graduationDate;

  GroupModel({
    required this.id,
    required this.name,
    this.specialization,
    required this.yearStarted,
    this.programId,
    this.courseId,
    this.status = 'active',
    this.graduationDate,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as int,
      name: json['name'] as String,
      specialization: json['specialization'] as String?,
      yearStarted: json['year_started'] as int? ?? 2024,
      programId: json['program_id'] as int?,
      courseId: json['course_id'] as int?,
      status: json['status'] as String? ?? 'active',
      graduationDate: json['graduation_date'] != null
          ? DateTime.parse(json['graduation_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'specialization': specialization,
    'year_started': yearStarted,
    'program_id': programId,
    'course_id': courseId,
    'status': status,
    'graduation_date': graduationDate?.toIso8601String(),
  };
}
