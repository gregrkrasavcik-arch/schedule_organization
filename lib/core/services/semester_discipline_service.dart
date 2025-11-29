import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/discipline_model.dart';

class SemesterDisciplineService {
  final SupabaseClient client;

  SemesterDisciplineService(this.client);

  // Дисциплины семестра (общие для всех групп)
  Future<List<DisciplineModel>> fetchForSemester(int semesterId) async {
    final data = await client
        .from('semester_disciplines')
        .select('discipline_id, disciplines(*)')
        .eq('semester_id', semesterId);

    return (data as List).map((e) {
      final discipline = e['disciplines'] as Map<String, dynamic>;
      return DisciplineModel.fromJson(discipline);
    }).toList();
  }

  // Дисциплины конкретной группы в семестре (общие + индивидуальные)
  Future<List<DisciplineModel>> fetchForGroupInSemester(
    int groupId,
    int semesterId,
  ) async {
    // Общие дисциплины семестра
    final semesterDisciplines = await fetchForSemester(semesterId);

    // Индивидуальные дисциплины группы
    final individualData = await client
        .from('group_semester_disciplines')
        .select('discipline_id, disciplines(*)')
        .eq('group_id', groupId)
        .eq('semester_id', semesterId);

    final individualDisciplines = (individualData as List).map((e) {
      final discipline = e['disciplines'] as Map<String, dynamic>;
      return DisciplineModel.fromJson(discipline);
    }).toList();

    // Объединяем (без дубликатов)
    final allDisciplines = {...semesterDisciplines, ...individualDisciplines};
    return allDisciplines.toList();
  }

  Future<void> assignDiscipline(int semesterId, int disciplineId) async {
    await client.from('semester_disciplines').insert({
      'semester_id': semesterId,
      'discipline_id': disciplineId,
    });
  }

  Future<void> removeDiscipline(int semesterId, int disciplineId) async {
    await client
        .from('semester_disciplines')
        .delete()
        .eq('semester_id', semesterId)
        .eq('discipline_id', disciplineId);
  }

  // Индивидуальная дисциплина для группы
  Future<void> assignIndividualDiscipline(
    int groupId,
    int semesterId,
    int disciplineId,
  ) async {
    await client.from('group_semester_disciplines').insert({
      'group_id': groupId,
      'semester_id': semesterId,
      'discipline_id': disciplineId,
    });
  }

  Future<void> removeIndividualDiscipline(
    int groupId,
    int semesterId,
    int disciplineId,
  ) async {
    await client
        .from('group_semester_disciplines')
        .delete()
        .eq('group_id', groupId)
        .eq('semester_id', semesterId)
        .eq('discipline_id', disciplineId);
  }
}
