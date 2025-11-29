import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/program_model.dart';

class ProgramService {
  final SupabaseClient client;

  ProgramService(this.client);

  Future<List<ProgramModel>> fetchAll() async {
    final data = await client
        .from('programs')
        .select()
        .order('name', ascending: true);
    return (data as List)
        .map((e) => ProgramModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> create(ProgramModel program) async {
    await client.from('programs').insert(program.toJson());
  }

  Future<void> update(int id, ProgramModel program) async {
    await client.from('programs').update(program.toJson()).eq('id', id);
  }

  Future<void> delete(int id) async {
    await client.from('programs').delete().eq('id', id);
  }
}
