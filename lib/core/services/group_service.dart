import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group_model.dart';

class GroupService {
  final SupabaseClient client;

  GroupService(this.client);

  Future<List<GroupModel>> fetchAll() async {
    final data = await client
        .from('groups')
        .select()
        .order('course_id', ascending: true)
        .order('year_started', ascending: false);
    return (data as List)
        .map((e) => GroupModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // Только активные группы
  Future<List<GroupModel>> fetchActive() async {
    final data = await client
        .from('groups')
        .select()
        .eq('status', 'active')
        .order('course_id', ascending: true)
        .order('year_started', ascending: false);
    return (data as List)
        .map((e) => GroupModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<GroupModel>> fetchByProgram(int programId) async {
    final data = await client
        .from('groups')
        .select()
        .eq('program_id', programId)
        .eq('status', 'active')
        .order('course_id', ascending: true)
        .order('year_started', ascending: false);
    return (data as List)
        .map((e) => GroupModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<GroupModel>> fetchByCourse(int courseId) async {
    final data = await client
        .from('groups')
        .select()
        .eq('course_id', courseId)
        .eq('status', 'active')
        .order('name', ascending: true);
    return (data as List)
        .map((e) => GroupModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> create(GroupModel group) async {
    await client.from('groups').insert(group.toJson());
  }

  Future<void> update(int id, GroupModel group) async {
    await client.from('groups').update(group.toJson()).eq('id', id);
  }

  // Перевести группу на следующий курс
  Future<void> advanceToCourse(int groupId, int newCourseId) async {
    await client
        .from('groups')
        .update({'course_id': newCourseId})
        .eq('id', groupId);
  }

  // Отметить группу как выпущенную
  Future<void> graduate(int groupId) async {
    await client
        .from('groups')
        .update({
          'status': 'graduated',
          'graduation_date': DateTime.now().toIso8601String(),
        })
        .eq('id', groupId);
  }

  // Архивировать группу (мягкое удаление)
  Future<void> archive(int groupId) async {
    await client
        .from('groups')
        .update({'status': 'archived'})
        .eq('id', groupId);
  }

  // Полное удаление группы и всех студентов
  Future<void> deleteWithStudents(int groupId) async {
    // Сначала удаляем студентов
    await client.from('students').delete().eq('group_id', groupId);
    // Потом удаляем саму группу
    await client.from('groups').delete().eq('id', groupId);
  }

  Future<void> delete(int id) async {
    await client.from('groups').delete().eq('id', id);
  }
}
