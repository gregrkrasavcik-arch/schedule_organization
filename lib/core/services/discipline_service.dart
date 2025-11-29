import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/discipline_model.dart';

class DisciplineService {
  final SupabaseClient client;

  DisciplineService(this.client);

  Future<List<DisciplineModel>> fetchAll() async {
    final data = await client
        .from('disciplines')
        .select()
        .order('name', ascending: true);
    return (data as List)
        .map((e) => DisciplineModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> create(DisciplineModel discipline) async {
    await client.from('disciplines').insert(discipline.toJson());
  }

  Future<void> update(int id, DisciplineModel discipline) async {
    await client.from('disciplines').update(discipline.toJson()).eq('id', id);
  }

  Future<void> delete(int id) async {
    await client.from('disciplines').delete().eq('id', id);
  }
}
