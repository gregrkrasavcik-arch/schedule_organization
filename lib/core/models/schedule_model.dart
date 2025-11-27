import 'package:flutter/material.dart';

class ScheduleModel {
  final int id;
  final String lessonName;
  final String teacher;
  final String classroom;
  final int weekday; // 1–7
  final String startTime; // "08:30:00"
  final String endTime; // "09:15:00"
  final DateTime? date; // конкретная дата
  final int loadScore; // шкала нагрузки 1–5
  final String? subjectColor; // hex, например "#42A5F5"
  final int? slotNumber; // номер пары

  ScheduleModel({
    required this.id,
    required this.lessonName,
    required this.teacher,
    required this.classroom,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    this.date,
    this.loadScore = 1,
    this.subjectColor,
    this.slotNumber,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] as int,
      lessonName: json['lesson_name'] as String? ?? '',
      teacher: json['teacher'] as String? ?? '',
      classroom: json['classroom'] as String? ?? '',
      weekday: (json['weekday'] is int)
          ? json['weekday'] as int
          : int.tryParse(json['weekday']?.toString() ?? '1') ?? 1,
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      date: json['date'] != null && json['date'].toString().isNotEmpty
          ? DateTime.tryParse(json['date'].toString())
          : null,
      loadScore: int.tryParse(json['load_score']?.toString() ?? '1') ?? 1,
      subjectColor: json['subject_color'] as String?,
      slotNumber: json['slot_number'] != null
          ? int.tryParse(json['slot_number'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'lesson_name': lessonName,
    'teacher': teacher,
    'classroom': classroom,
    'weekday': weekday,
    'start_time': startTime,
    'end_time': endTime,
    'date': date?.toIso8601String(),
    'load_score': loadScore,
    'subject_color': subjectColor,
    'slot_number': slotNumber,
  };
}

Color parseHexColor(String? hex, {Color fallback = const Color(0xFF5C6BC0)}) {
  if (hex == null || hex.isEmpty) return fallback;
  var cleaned = hex.replaceAll('#', '');
  if (cleaned.length == 6) cleaned = 'FF$cleaned';
  final value = int.tryParse('0x$cleaned');
  if (value == null) return fallback;
  return Color(value);
}
