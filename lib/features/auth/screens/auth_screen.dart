import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';

import '../../../core/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  String _selectedRole = 'student';

  late final AuthService _auth;

  @override
  void initState() {
    super.initState();
    _auth = AuthService(); // ✅ БЕЗ параметров
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      if (_isLogin) {
        // ✅ Правильный вызов signIn
        await _auth.signIn(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
      } else {
        // ✅ Правильный вызов signUp
        await _auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
          fullName: _nameCtrl.text.trim(),
          role: _selectedRole,
        );
      }

      if (!mounted) return;
      // Navigator automatically redirects via AppRouter
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF283593), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isLogin ? 'Вход' : 'Регистрация',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isLogin
                                  ? 'Добро пожаловать обратно'
                                  : 'Создайте новый аккаунт',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ФИО (только при регистрации)
                            if (!_isLogin) ...[
                              _buildTextField(
                                controller: _nameCtrl,
                                label: 'ФИО',
                                hint: 'Иван Иванович Иванов',
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Введите имя'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Email
                            _buildTextField(
                              controller: _emailCtrl,
                              label: 'Email',
                              hint: 'email@college.com',
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v == null || !v.contains('@')
                                  ? 'Неверный email'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Пароль
                            _buildTextField(
                              controller: _passCtrl,
                              label: 'Пароль',
                              hint: 'Минимум 6 символов',
                              obscureText: true,
                              validator: (v) => v == null || v.length < 6
                                  ? 'Минимум 6 символов'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Выбор роли (только при регистрации)
                            if (!_isLogin) ...[
                              _buildRoleDropdown(),
                              const SizedBox(height: 16),
                            ],

                            // Кнопка вход/регистрация
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.withOpacity(0.8),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        _isLogin ? 'Войти' : 'Создать аккаунт',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Переключатель логин/регистрация
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isLogin
                                      ? 'Нет аккаунта? '
                                      : 'Уже есть аккаунт? ',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _isLogin = !_isLogin),
                                  child: Text(
                                    _isLogin ? 'Зарегистрироваться' : 'Войти',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(
        color: Colors.white, // ✅ БЕЛЫЙ ТЕКСТ - теперь видно!
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      dropdownColor: Colors.blue.shade900,
      decoration: InputDecoration(
        labelText: 'Роль',
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
      items: [
        DropdownMenuItem(value: 'student', child: const Text('Студент')),
        DropdownMenuItem(value: 'teacher', child: const Text('Преподаватель')),
        DropdownMenuItem(value: 'admin', child: const Text('Администратор')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedRole = value);
        }
      },
    );
  }
}
