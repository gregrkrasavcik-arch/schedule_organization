import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/semester_model.dart';

class SemesterService {
  final SupabaseClient client;

  SemesterService(this.client);

  // Получить семестры по курсу
  Future<List<SemesterModel>> fetchByCourse(int courseId) async {
    final data = await client
        .from('semesters')
        .select()
        .eq('course_id', courseId)
        .order('semester_number', ascending: true);
    return (data as List)
        .map((e) => SemesterModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // Получить семестры по программе (старый метод, для совместимости)
  Future<List<SemesterModel>> fetchByProgram(int programId) async {
    final data = await client
        .from('semesters')
        .select()
        .eq('program_id', programId)
        .order('semester_number', ascending: true);
    return (data as List)
        .map((e) => SemesterModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> create(SemesterModel semester) async {
    await client.from('semesters').insert(semester.toJson());
  }

  Future<void> update(int id, SemesterModel semester) async {
    await client.from('semesters').update(semester.toJson()).eq('id', id);
  }

  Future<void> delete(int id) async {
    await client.from('semesters').delete().eq('id', id);
  }
}
