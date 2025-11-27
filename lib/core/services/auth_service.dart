import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient client;

  AuthService(this.client);

  Future<AuthResponse> signIn(String email, String password) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(
    String email,
    String password,
    String fullName,
  ) async {
    final res = await client.auth.signUp(email: email, password: password);

    final user = res.user; // важная строчка
    if (user != null) {
      await client.from('profiles').insert({
        'id': user.id,
        'full_name': fullName,
        'role': 'student',
      });
    }

    return res;
  }

  Future<void> signOut() => client.auth.signOut();

  Session? get currentSession => client.auth.currentSession;
}
