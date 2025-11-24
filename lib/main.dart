import 'package:flutter/material.dart';
import 'features/schedule/screens/schedule_list_screen.dart';
import 'features/schedule/screens/schedule_add_screen.dart';

// ... остальной код

class MainMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Главное меню')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text('Просмотреть расписание'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ScheduleListScreen()),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              child: Text('Добавить расписание'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ScheduleAddScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
