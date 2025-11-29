import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course_model.dart';

class CourseService {
  final SupabaseClient client;

  CourseService(this.client);

  Future<List<CourseModel>> fetchByProgram(int programId) async {
    final data = await client
        .from('courses')
        .select()
        .eq('program_id', programId)
        .order('course_number', ascending: true);
    return (data as List)
        .map((e) => CourseModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> create(CourseModel course) async {
    await client.from('courses').insert(course.toJson());
  }

  Future<void> update(int id, CourseModel course) async {
    await client.from('courses').update(course.toJson()).eq('id', id);
  }

  Future<void> delete(int id) async {
    await client.from('courses').delete().eq('id', id);
  }
}
