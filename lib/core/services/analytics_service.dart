import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsData {
  final int totalPairs;
  final int totalGroups;
  final int totalTeachers;
  final int totalStudents;
  final double averageLoadPerDay;
  final Map<int, int> loadByWeekday;
  final Map<String, int> pairsByGroup;
  final Map<String, int> pairsByTeacher;
  final List<String> problems;

  AnalyticsData({
    required this.totalPairs,
    required this.totalGroups,
    required this.totalTeachers,
    required this.totalStudents,
    required this.averageLoadPerDay,
    required this.loadByWeekday,
    required this.pairsByGroup,
    required this.pairsByTeacher,
    required this.problems,
  });
}

class AnalyticsService {
  final SupabaseClient client;

  AnalyticsService(this.client);

  Future<AnalyticsData> getAnalytics() async {
    try {
      final scheduleList = await client.from('schedule').select();
      final groupsList = await client
          .from('groups')
          .select()
          .eq('status', 'active');
      final teachersList = await client.from('teachers').select();
      final studentsList = await client.from('students').select();

      final totalPairs = (scheduleList as List).length;
      final totalGroups = (groupsList as List).length;
      final totalTeachers = (teachersList as List).length;
      final totalStudents = (studentsList as List).length;

      // Нагрузка по дням (безопасно)
      final loadByWeekday = <int, int>{};
      for (int i = 1; i <= 7; i++) {
        loadByWeekday[i] = 0;
      }

      for (final pair in scheduleList as List) {
        try {
          final map = pair as Map<String, dynamic>;
          final weekday = _toInt(map['weekday']);
          final load = _toInt(map['load_score']) ?? 1;

          if (weekday != null && weekday >= 1 && weekday <= 7) {
            loadByWeekday[weekday] = (loadByWeekday[weekday] ?? 0) + load;
          }
        } catch (e) {
          continue;
        }
      }

      final totalLoad = loadByWeekday.values.fold<int>(
        0,
        (sum, val) => sum + val,
      );
      final averageLoadPerDay = totalLoad > 0 ? totalLoad / 7.0 : 0.0;

      // Пары по группам
      final pairsByGroup = <String, int>{};
      for (final pair in scheduleList as List) {
        try {
          final map = pair as Map<String, dynamic>;
          final groupId = _toInt(map['group_id']);

          if (groupId != null) {
            for (final group in groupsList as List) {
              final gMap = group as Map<String, dynamic>;
              if (_toInt(gMap['id']) == groupId) {
                final name = gMap['name'] as String? ?? 'Unknown';
                pairsByGroup[name] = (pairsByGroup[name] ?? 0) + 1;
                break;
              }
            }
          }
        } catch (e) {
          continue;
        }
      }

      // Пары по преподавателям
      final pairsByTeacher = <String, int>{};
      for (final pair in scheduleList as List) {
        try {
          final map = pair as Map<String, dynamic>;
          final teacherId = _toInt(map['teacher_id']);

          if (teacherId != null) {
            for (final teacher in teachersList as List) {
              final tMap = teacher as Map<String, dynamic>;
              if (_toInt(tMap['id']) == teacherId) {
                final name = tMap['full_name'] as String? ?? 'Unknown';
                pairsByTeacher[name] = (pairsByTeacher[name] ?? 0) + 1;
                break;
              }
            }
          }
        } catch (e) {
          continue;
        }
      }

      // Проблемы
      final problems = <String>[];

      for (final entry in loadByWeekday.entries) {
        if (entry.value > 10) {
          problems.add('⚠️ ${_dayName(entry.key)}: ${entry.value}ч (>10)');
        }
      }

      for (final group in groupsList as List) {
        try {
          final gMap = group as Map<String, dynamic>;
          final gId = _toInt(gMap['id']);
          if (gId != null) {
            bool has = false;
            for (final p in scheduleList as List) {
              if (_toInt((p as Map)['group_id']) == gId) {
                has = true;
                break;
              }
            }
            if (!has) {
              problems.add('❌ Группа "${gMap['name']}" без расписания');
            }
          }
        } catch (e) {
          continue;
        }
      }

      return AnalyticsData(
        totalPairs: totalPairs,
        totalGroups: totalGroups,
        totalTeachers: totalTeachers,
        totalStudents: totalStudents,
        averageLoadPerDay: averageLoadPerDay,
        loadByWeekday: loadByWeekday,
        pairsByGroup: pairsByGroup,
        pairsByTeacher: pairsByTeacher,
        problems: problems.isNotEmpty ? problems : ['✅ Проблем нет'],
      );
    } catch (e) {
      print('Analytics error: $e');
      return AnalyticsData(
        totalPairs: 0,
        totalGroups: 0,
        totalTeachers: 0,
        totalStudents: 0,
        averageLoadPerDay: 0,
        loadByWeekday: {},
        pairsByGroup: {},
        pairsByTeacher: {},
        problems: ['⚠️ Ошибка: $e'],
      );
    }
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _dayName(int day) {
    const names = ['', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return day >= 0 && day < names.length ? names[day] : 'Day$day';
  }
}
