import 'features/auth/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase_config.dart';
import 'features/schedule/screens/schedule_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  await initializeDateFormatting('ru_RU', null);

  runApp(const CollegeScheduleApp());
}

class CollegeScheduleApp extends StatelessWidget {
  const CollegeScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5C6BC0),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'AI Расписание колледжа',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black.withOpacity(0.02),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      home: Supabase.instance.client.auth.currentSession == null
          ? const AuthScreen()
          : const ScheduleListScreen(),
    );
  }
}
