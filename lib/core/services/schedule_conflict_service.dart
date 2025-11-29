import 'package:supabase_flutter/supabase_flutter.dart';

class ScheduleConflict {
  final String type; // 'group', 'teacher', 'classroom'
  final String message;
  final String? conflictingPairName;

  ScheduleConflict({
    required this.type,
    required this.message,
    this.conflictingPairName,
  });
}

class ScheduleConflictService {
  final SupabaseClient client;

  ScheduleConflictService(this.client);

  /// Проверить конфликт группы
  Future<ScheduleConflict?> checkGroupConflict({
    required int groupId,
    required String startTime,
    required String endTime,
    required int weekday,
    String? date,
    int? excludeScheduleId,
  }) async {
    try {
      final query = client
          .from('schedule')
          .select()
          .eq('group_id', groupId)
          .eq('weekday', weekday);

      final data = await query;
      final list = data as List;

      for (final item in list) {
        if (excludeScheduleId != null && item['id'] == excludeScheduleId) {
          continue;
        }

        final pairStart = item['start_time'] as String?;
        final pairEnd = item['end_time'] as String?;

        if (pairStart != null &&
            pairEnd != null &&
            _timesOverlap(startTime, endTime, pairStart, pairEnd)) {
          return ScheduleConflict(
            type: 'group',
            message:
                'Группа уже занята в это время на паре "${item['lesson_name']}"!',
            conflictingPairName: item['lesson_name'],
          );
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Проверить конфликт преподавателя
  Future<ScheduleConflict?> checkTeacherConflict({
    required int teacherId,
    required String startTime,
    required String endTime,
    required int weekday,
    String? date,
    int? excludeScheduleId,
  }) async {
    try {
      final query = client
          .from('schedule')
          .select()
          .eq('teacher_id', teacherId)
          .eq('weekday', weekday);

      final data = await query;
      final list = data as List;

      for (final item in list) {
        if (excludeScheduleId != null && item['id'] == excludeScheduleId) {
          continue;
        }

        final pairStart = item['start_time'] as String?;
        final pairEnd = item['end_time'] as String?;

        if (pairStart != null &&
            pairEnd != null &&
            _timesOverlap(startTime, endTime, pairStart, pairEnd)) {
          return ScheduleConflict(
            type: 'teacher',
            message:
                'Преподаватель уже ведет "${item['lesson_name']}" в это время!',
            conflictingPairName: item['lesson_name'],
          );
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Проверить конфликт аудитории
  Future<ScheduleConflict?> checkClassroomConflict({
    required String classroom,
    required String startTime,
    required String endTime,
    required int weekday,
    String? date,
    int? excludeScheduleId,
  }) async {
    try {
      final query = client
          .from('schedule')
          .select()
          .eq('classroom', classroom)
          .eq('weekday', weekday);

      final data = await query;
      final list = data as List;

      for (final item in list) {
        if (excludeScheduleId != null && item['id'] == excludeScheduleId) {
          continue;
        }

        final pairStart = item['start_time'] as String?;
        final pairEnd = item['end_time'] as String?;

        if (pairStart != null &&
            pairEnd != null &&
            _timesOverlap(startTime, endTime, pairStart, pairEnd)) {
          return ScheduleConflict(
            type: 'classroom',
            message:
                'Аудитория $classroom уже занята на паре "${item['lesson_name']}"!',
            conflictingPairName: item['lesson_name'],
          );
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Проверить все конфликты разом
  Future<List<ScheduleConflict>> checkAllConflicts({
    required int? groupId,
    required int? teacherId,
    required String classroom,
    required String startTime,
    required String endTime,
    required int weekday,
    String? date,
    int? excludeScheduleId,
  }) async {
    final conflicts = <ScheduleConflict>[];

    if (groupId != null) {
      final groupConflict = await checkGroupConflict(
        groupId: groupId,
        startTime: startTime,
        endTime: endTime,
        weekday: weekday,
        date: date,
        excludeScheduleId: excludeScheduleId,
      );
      if (groupConflict != null) conflicts.add(groupConflict);
    }

    if (teacherId != null) {
      final teacherConflict = await checkTeacherConflict(
        teacherId: teacherId,
        startTime: startTime,
        endTime: endTime,
        weekday: weekday,
        date: date,
        excludeScheduleId: excludeScheduleId,
      );
      if (teacherConflict != null) conflicts.add(teacherConflict);
    }

    final classroomConflict = await checkClassroomConflict(
      classroom: classroom,
      startTime: startTime,
      endTime: endTime,
      weekday: weekday,
      date: date,
      excludeScheduleId: excludeScheduleId,
    );
    if (classroomConflict != null) conflicts.add(classroomConflict);

    return conflicts;
  }

  /// Проверить перекрытие времени
  bool _timesOverlap(String start1, String end1, String start2, String end2) {
    try {
      // Парсим время (формат HH:MM:SS)
      final parts1Start = start1.split(':');
      final parts1End = end1.split(':');
      final parts2Start = start2.split(':');
      final parts2End = end2.split(':');

      final t1Start =
          int.parse(parts1Start[0]) * 60 + int.parse(parts1Start[1]);
      final t1End = int.parse(parts1End[0]) * 60 + int.parse(parts1End[1]);
      final t2Start =
          int.parse(parts2Start[0]) * 60 + int.parse(parts2Start[1]);
      final t2End = int.parse(parts2End[0]) * 60 + int.parse(parts2End[1]);

      // Проверяем перекрытие: NOT (end1 <= start2 OR end2 <= start1)
      return !(t1End <= t2Start || t2End <= t1Start);
    } catch (e) {
      return false;
    }
  }
}
