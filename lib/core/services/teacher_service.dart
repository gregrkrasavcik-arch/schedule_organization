import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/teacher_model.dart';

class TeacherService {
  final SupabaseClient client;

  TeacherService(this.client);

  Future<List<TeacherModel>> fetchAll() async {
    final data = await client
        .from('teachers')
        .select()
        .order('full_name', ascending: true);
    return (data as List)
        .map((e) => TeacherModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> create(TeacherModel teacher) async {
    await client.from('teachers').insert(teacher.toJson());
  }

  Future<void> update(int id, TeacherModel teacher) async {
    await client.from('teachers').update(teacher.toJson()).eq('id', id);
  }

  Future<void> delete(int id) async {
    await client.from('teachers').delete().eq('id', id);
  }
}
