import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/group_model.dart';
import '../../../core/models/program_model.dart';
import '../../../core/models/course_model.dart';
import '../../../core/services/group_service.dart';
import '../../../core/services/program_service.dart';
import '../../../core/services/course_service.dart';

class GroupCourseTransitionScreen extends StatefulWidget {
  const GroupCourseTransitionScreen({super.key});

  @override
  State<GroupCourseTransitionScreen> createState() =>
      _GroupCourseTransitionScreenState();
}

class _GroupCourseTransitionScreenState
    extends State<GroupCourseTransitionScreen> {
  List<GroupModel> _groups = [];
  List<ProgramModel> _programs = [];
  List<CourseModel> _courses = [];
  bool _loading = true;

  late final GroupService _groupService;
  late final ProgramService _programService;
  late final CourseService _courseService;

  @override
  void initState() {
    super.initState();
    _groupService = GroupService(Supabase.instance.client);
    _programService = ProgramService(Supabase.instance.client);
    _courseService = CourseService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final groups = await _groupService.fetchActive();
      final programs = await _programService.fetchAll();
      setState(() {
        _groups = groups;
        _programs = programs;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _advanceGroup(GroupModel group) async {
    if (group.programId == null) return;

    try {
      final courses = await _courseService.fetchByProgram(group.programId!);

      if (!mounted) return;

      final program = _programs.firstWhere((p) => p.id == group.programId);
      final currentCourseNumber = group.courseId != null
          ? courses.firstWhere((c) => c.id == group.courseId).courseNumber
          : 0;
      final nextCourseNumber = currentCourseNumber + 1;

      if (nextCourseNumber > program.durationYears) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Группа достигла максимального курса. Рекомендуется отметить как выпущенную.',
            ),
          ),
        );
        return;
      }

      final nextCourse = courses.firstWhere(
        (c) => c.courseNumber == nextCourseNumber,
      );

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Перевести группу на следующий курс?'),
          content: Text('${group.name} → Курс ${nextCourseNumber}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _groupService.advanceToCourse(group.id, nextCourse.id);
                  _load();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Группа переведена на следующий курс'),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                }
              },
              child: const Text('Перевести'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _graduateGroup(GroupModel group) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Отметить как выпущенную?'),
            content: Text('Группа ${group.name} завершила обучение.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Выпустить'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    try {
      await _groupService.graduate(group.id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _deleteGroupWithStudents(GroupModel group) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('ОПАСНО: Полное удаление'),
            content: Text(
              'Удалить группу ${group.name} и всех её студентов?\n\n'
              'Это действие необратимо!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Удалить',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    try {
      await _groupService.deleteWithStudents(group.id);
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Группа и студенты удалены')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  String _getCourseName(GroupModel group) {
    if (group.courseId == null) return 'Без курса';
    try {
      final program = _programs.firstWhere((p) => p.id == group.programId);
      return 'Курс ${group.courseId}/${program.durationYears}';
    } catch (_) {
      return 'Курс ${group.courseId}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Переводы групп на курсы')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
          ? const Center(child: Text('Активных групп нет'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _groups.length,
              itemBuilder: (context, i) {
                final g = _groups[i];
                final courseName = _getCourseName(g);

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(g.name),
                    subtitle: Text('${g.specialization ?? "—"} • $courseName'),
                    trailing: PopupMenuButton(
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          onTap: () => _advanceGroup(g),
                          child: const Text('→ Следующий курс'),
                        ),
                        PopupMenuItem(
                          onTap: () => _graduateGroup(g),
                          child: const Text('✓ Выпустить'),
                        ),
                        PopupMenuItem(
                          onTap: () => _deleteGroupWithStudents(g),
                          child: const Text(
                            'Удалить группу',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
