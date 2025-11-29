import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_model.dart';

class StudentService {
  final SupabaseClient client;

  StudentService(this.client);

  Future<List<StudentModel>> fetchAll() async {
    final data = await client
        .from('students')
        .select()
        .order('full_name', ascending: true);
    return (data as List)
        .map((e) => StudentModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<StudentModel>> fetchByGroup(int groupId) async {
    final data = await client
        .from('students')
        .select()
        .eq('group_id', groupId)
        .order('full_name', ascending: true);
    return (data as List)
        .map((e) => StudentModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> create(StudentModel student) async {
    await client.from('students').insert(student.toJson());
  }

  Future<void> createBatch(List<StudentModel> students) async {
    final batch = students.map((s) => s.toJson()).toList();
    await client.from('students').insert(batch);
  }

  Future<void> update(int id, StudentModel student) async {
    await client.from('students').update(student.toJson()).eq('id', id);
  }

  Future<void> delete(int id) async {
    await client.from('students').delete().eq('id', id);
  }
}
