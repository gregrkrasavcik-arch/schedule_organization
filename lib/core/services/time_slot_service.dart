import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/time_slot_model.dart';

class TimeSlotService {
  final SupabaseClient client;

  TimeSlotService(this.client);

  Future<List<TimeSlotModel>> fetchForWeekday(int weekday) async {
    final data = await client
        .from('time_slots')
        .select()
        .eq('weekday', weekday)
        .order('slot_number', ascending: true);

    return (data as List)
        .map((e) => TimeSlotModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<TimeSlotModel>> fetchAll() async {
    final data = await client
        .from('time_slots')
        .select()
        .order('weekday', ascending: true)
        .order('slot_number', ascending: true);

    return (data as List)
        .map((e) => TimeSlotModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> upsert(TimeSlotModel slot) async {
    if (slot.id == 0) {
      await client.from('time_slots').insert(slot.toJson());
    } else {
      await client.from('time_slots').update(slot.toJson()).eq('id', slot.id);
    }
  }

  Future<void> delete(int id) async {
    await client.from('time_slots').delete().eq('id', id);
  }
}
