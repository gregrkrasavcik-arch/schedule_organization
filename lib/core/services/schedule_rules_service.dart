import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/schedule_rules_model.dart';

class ScheduleRulesService {
  final SupabaseClient client;

  ScheduleRulesService(this.client);

  Future<ScheduleRules> fetch() async {
    final data = await client
        .from('schedule_rules')
        .select()
        .limit(1)
        .maybeSingle();
    if (data == null) {
      return ScheduleRules(
        id: 0,
        maxLoadPerDay: 10,
        maxPairsPerDay: 6,
        hardDays: const [2, 3],
      );
    }
    return ScheduleRules.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> save(ScheduleRules rules) async {
    if (rules.id == 0) {
      await client.from('schedule_rules').insert({
        'name': 'default',
        'max_load_per_day': rules.maxLoadPerDay,
        'max_pairs_per_day': rules.maxPairsPerDay,
        'hard_days': rules.hardDays,
      });
    } else {
      await client
          .from('schedule_rules')
          .update({
            'max_load_per_day': rules.maxLoadPerDay,
            'max_pairs_per_day': rules.maxPairsPerDay,
            'hard_days': rules.hardDays,
          })
          .eq('id', rules.id);
    }
  }
}
