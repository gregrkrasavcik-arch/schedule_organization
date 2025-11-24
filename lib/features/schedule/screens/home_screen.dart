import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatelessWidget {
  // Тестовая функция для Supabase
  void _testSupabase() async {
    final client = Supabase.instance.client;
    try {
      final response = await client
          .from('schedule')
          .insert({'message_text': "Привет из Flutter!"});
      print("Успешно записал: $response");

      final res = await client
          .from('schedule')
          .select()
          .order('id', ascending: false)
          .limit(3);
      print("Прочитано: $res");
    } catch (error) {
      print('Ошибка работы с Supabase: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Расписание')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Добро пожаловать!\nВаше первое AI-расписание.',
              style: TextStyle(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _testSupabase,
              child: Text('Тест записи и чтения из Supabase'),
            ),
          ],
        ),
      ),
    );
  }
}
