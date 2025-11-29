import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/semester_model.dart';

class GroupSemesterService {
  final SupabaseClient client;

  GroupSemesterService(this.client);

  // Какой семестр сейчас проходит группа
  Future<SemesterModel?> fetchCurrentSemesterForGroup(int groupId) async {
    final data = await client
        .from('group_semesters')
        .select('semester_id, semesters(*)')
        .eq('group_id', groupId)
        .maybeSingle();

    if (data == null) return null;
    final semester = data['semesters'] as Map<String, dynamic>;
    return SemesterModel.fromJson(semester);
  }

  // Все семестры группы
  Future<List<SemesterModel>> fetchSemestersForGroup(int groupId) async {
    final data = await client
        .from('group_semesters')
        .select('semester_id, semesters(*)')
        .eq('group_id', groupId);

    return (data as List).map((e) {
      final semester = e['semesters'] as Map<String, dynamic>;
      return SemesterModel.fromJson(semester);
    }).toList();
  }

  // Какие группы в этом семестре
  Future<List<int>> fetchGroupsInSemester(int semesterId) async {
    final data = await client
        .from('group_semesters')
        .select('group_id')
        .eq('semester_id', semesterId);

    return (data as List).map((e) => e['group_id'] as int).toList();
  }

  // Назначить группу на семестр
  Future<void> assignGroupToSemester(int groupId, int semesterId) async {
    // Сначала удаляем старое назначение
    await client.from('group_semesters').delete().eq('group_id', groupId);
    // Добавляем новое
    await client.from('group_semesters').insert({
      'group_id': groupId,
      'semester_id': semesterId,
    });
  }
}
