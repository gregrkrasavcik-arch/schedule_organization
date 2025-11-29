import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Регистрация
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'role': role},
      );

      // Создаём профиль в таблице profiles
      if (response.user != null) {
        await _supabase.from('profiles').insert({
          'id': response.user!.id,
          'full_name': fullName,
          'role': role,
        });
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Вход
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Выход
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Получить роль текущего пользователя
  Future<String?> getCurrentUserRole() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      return profile['role'] as String?;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Получить полный профиль
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return profile as Map<String, dynamic>;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Stream для отслеживания изменений состояния авторизации
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Получить текущего пользователя
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }
}
