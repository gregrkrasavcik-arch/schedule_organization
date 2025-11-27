import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/auth_service.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _avatarCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  String _email = '';
  String _role = 'student';

  late final SupabaseClient _client;
  late final AuthService _auth;

  @override
  void initState() {
    super.initState();
    _client = Supabase.instance.client;
    _auth = AuthService(_client);
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _avatarCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      return;
    }

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      setState(() {
        _email = user.email ?? '';
        _nameCtrl.text = data?['full_name']?.toString() ?? '';
        _avatarCtrl.text = data?['avatar_url']?.toString() ?? '';
        _role = data?['role']?.toString() ?? 'student';
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки профиля: $e')));
    }
  }

  Future<void> _saveProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await _client
          .from('profiles')
          .update({
            'full_name': _nameCtrl.text.trim(),
            'avatar_url': _avatarCtrl.text.trim().isEmpty
                ? null
                : _avatarCtrl.text.trim(),
          })
          .eq('id', user.id);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Профиль обновлён')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPassCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пароль минимум 6 символов')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _client.auth.updateUser(
        UserAttributes(password: _newPassCtrl.text.trim()),
      );
      _newPassCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Пароль обновлён')));
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.blueGrey.shade700,
                      backgroundImage: _avatarCtrl.text.isNotEmpty
                          ? NetworkImage(_avatarCtrl.text.trim())
                          : null,
                      child: _avatarCtrl.text.isEmpty
                          ? Text(
                              _email.isNotEmpty ? _email[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameCtrl.text.isEmpty
                                ? 'Без имени'
                                : _nameCtrl.text,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Роль: $_role',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'ФИО'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _avatarCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL аватара',
                    helperText: 'Вставьте ссылку на картинку',
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newPassCtrl,
                  decoration: const InputDecoration(labelText: 'Новый пароль'),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _saving ? null : _changePassword,
                    child: const Text('Сменить пароль'),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveProfile,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Сохранить профиль'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _logout,
                    child: const Text('Выйти из аккаунта'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
