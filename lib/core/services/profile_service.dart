import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient client;

  ProfileService(this.client);

  Future<String> fetchRole() async {
    final user = client.auth.currentUser;
    if (user == null) return 'guest';

    final data = await client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    return (data?['role'] as String?) ?? 'student';
  }

  Future<int?> fetchGroupId() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final data = await client
        .from('profiles')
        .select('group_id')
        .eq('id', user.id)
        .maybeSingle();

    return (data?['group_id'] as int?);
  }

  Future<Map<String, dynamic>?> fetchProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final data = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return data != null ? Map<String, dynamic>.from(data) : null;
  }
}
