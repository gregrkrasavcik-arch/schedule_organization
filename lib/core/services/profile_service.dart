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
}
