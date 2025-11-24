class ScheduleModel {
  final int id;
  final String lessonName;
  final String teacher;
  final String classroom;
  final int weekday;
  final String startTime;
  final String endTime;

  ScheduleModel({
    required this.id,
    required this.lessonName,
    required this.teacher,
    required this.classroom,
    required this.weekday,
    required this.startTime,
    required this.endTime,
  });

  // Преобразование из Supabase-JSON
  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] as int,
      lessonName: json['lesson_name'] as String,
      teacher: json['teacher'] as String,
      classroom: json['classroom'] as String,
      weekday: json['weekday'] as int,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
    );
  }

  // Преобразование в Supabase-JSON
  Map<String, dynamic> toJson() => {
    'lesson_name': lessonName,
    'teacher': teacher,
    'classroom': classroom,
    'weekday': weekday,
    'start_time': startTime,
    'end_time': endTime,
  };
}
