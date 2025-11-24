import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScheduleAddScreen extends StatefulWidget {
  @override
  State<ScheduleAddScreen> createState() => _ScheduleAddScreenState();
}

class _ScheduleAddScreenState extends State<ScheduleAddScreen> {
  final _formKey = GlobalKey<FormState>();
  String lessonName = '';
  String teacher = '';
  String classroom = '';
  int weekday = 1;
  String startTime = '';
  String endTime = '';

  // Список дней недели
  final dayNames = [
    'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'
  ];

  Future<void> _saveSchedule() async {
    final client = Supabase.instance.client;
    await client.from('schedule').insert({
      'lesson_name': lessonName,
      'teacher': teacher,
      'classroom': classroom,
      'weekday': weekday,
      'start_time': startTime,
      'end_time': endTime,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Расписание добавлено!'))
    );
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Добавить расписание')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Название предмета'),
                onSaved: (val) => lessonName = val ?? '',
                validator: (val) => val == null || val.isEmpty ? 'Введите предмет' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Преподаватель'),
                onSaved: (val) => teacher = val ?? '',
                validator: (val) => val == null || val.isEmpty ? 'Введите преподавателя' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Аудитория'),
                onSaved: (val) => classroom = val ?? '',
                validator: (val) => val == null || val.isEmpty ? 'Введите аудиторию' : null,
              ),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'День недели'),
                value: weekday,
                onChanged: (val) => setState(() => weekday = val ?? 1),
                items: List.generate(dayNames.length, (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text(dayNames[index]),
                )),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Время начала (например, 08:30)'),
                onSaved: (val) => startTime = val ?? '',
                validator: (val) => val == null || val.isEmpty ? 'Введите время начала' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Время окончания (например, 09:15)'),
                onSaved: (val) => endTime = val ?? '',
                validator: (val) => val == null || val.isEmpty ? 'Введите время окончания' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    _saveSchedule();
                  }
                },
                child: Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
