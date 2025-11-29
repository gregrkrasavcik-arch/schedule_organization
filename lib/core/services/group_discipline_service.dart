import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group_discipline_model.dart';
import '../models/discipline_model.dart';

class GroupDisciplineService {
  final SupabaseClient client;

  GroupDisciplineService(this.client);

  Future<List<DisciplineModel>> fetchForGroup(int groupId) async {
    final data = await client
        .from('group_disciplines')
        .select('discipline_id, disciplines(*)')
        .eq('group_id', groupId);

    return (data as List).map((e) {
      final discipline = e['disciplines'] as Map<String, dynamic>;
      return DisciplineModel.fromJson(discipline);
    }).toList();
  }

  Future<void> assignDiscipline(
    int groupId,
    int disciplineId, {
    bool isCommon = false,
  }) async {
    await client.from('group_disciplines').insert({
      'group_id': groupId,
      'discipline_id': disciplineId,
      'is_common': isCommon,
    });
  }

  Future<void> removeDiscipline(int groupId, int disciplineId) async {
    await client
        .from('group_disciplines')
        .delete()
        .eq('group_id', groupId)
        .eq('discipline_id', disciplineId);
  }
}
