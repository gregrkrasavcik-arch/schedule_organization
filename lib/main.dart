import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/auth_service.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/student/screens/student_app.dart';
import 'features/teacher/screens/teacher_app.dart';
import 'features/admin/screens/admin_app.dart';
import 'features/admin/screens/analytics_screen.dart'; // ← ДОБАВЬ

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://your-project.supabase.co',
    anonKey: 'your-anon-key',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'College Timetable',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      home: const AppRouter(),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;

        if (session == null) {
          return const AuthScreen();
        }

        return FutureBuilder<String?>(
          future: AuthService().getCurrentUserRole(),
          builder: (context, roleSnapshot) {
            if (!roleSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = roleSnapshot.data ?? 'student';

            // ✅ ГЛАВНОЕ ИЗМЕНЕНИЕ: показываем AnalyticsScreen ДЛЯ ВСЕХ
            if (role == 'admin') {
              return const AdminApp();
            } else if (role == 'teacher') {
              return const TeacherApp();
            } else {
              return const StudentApp();
            }
          },
        );
      },
    );
  }
}
