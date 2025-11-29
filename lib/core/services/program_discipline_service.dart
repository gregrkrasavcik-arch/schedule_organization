import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/discipline_model.dart';

class ProgramDisciplineService {
  final SupabaseClient client;

  ProgramDisciplineService(this.client);

  Future<List<DisciplineModel>> fetchForProgram(int programId) async {
    final data = await client
        .from('program_disciplines')
        .select('discipline_id, disciplines(*)')
        .eq('program_id', programId);

    return (data as List).map((e) {
      final discipline = e['disciplines'] as Map<String, dynamic>;
      return DisciplineModel.fromJson(discipline);
    }).toList();
  }

  Future<void> assignDiscipline(int programId, int disciplineId) async {
    await client.from('program_disciplines').insert({
      'program_id': programId,
      'discipline_id': disciplineId,
    });
  }

  Future<void> removeDiscipline(int programId, int disciplineId) async {
    await client
        .from('program_disciplines')
        .delete()
        .eq('program_id', programId)
        .eq('discipline_id', disciplineId);
  }
}
