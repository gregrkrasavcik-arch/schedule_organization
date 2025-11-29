import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/program_model.dart';
import '../../../core/models/course_model.dart';
import '../../../core/services/course_service.dart';
import 'course_management_screen.dart';

class CoursesScreen extends StatefulWidget {
  final ProgramModel program;

  const CoursesScreen({required this.program});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<CourseModel> _courses = [];
  bool _loading = true;

  late final CourseService _service;

  @override
  void initState() {
    super.initState();
    _service = CourseService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final courses = await _service.fetchByProgram(widget.program.id);
      setState(() {
        _courses = courses;
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

  Future<void> _openAdd([CourseModel? model]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _CourseFormScreen(model: model, programId: widget.program.id),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _delete(int id) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Удалить курс?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Удалить'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    try {
      await _service.delete(id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  void _manageCourse(CourseModel course) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CourseManagementScreen(course: course)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Курсы: ${widget.program.name}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(),
        shape: const StadiumBorder(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
          ? const Center(child: Text('Курсов нет'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _courses.length,
              itemBuilder: (context, i) {
                final c = _courses[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(c.name ?? '${c.courseNumber}-й курс'),
                    subtitle: Text('Номер: ${c.courseNumber}'),
                    trailing: PopupMenuButton(
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          onTap: () => _manageCourse(c),
                          child: const Text('Управление'),
                        ),
                        PopupMenuItem(
                          onTap: () => _openAdd(c),
                          child: const Text('Редактировать'),
                        ),
                        PopupMenuItem(
                          onTap: () => _delete(c.id),
                          child: const Text('Удалить'),
                        ),
                      ],
                    ),
                    onTap: () => _manageCourse(c),
                  ),
                );
              },
            ),
    );
  }
}

class _CourseFormScreen extends StatefulWidget {
  final CourseModel? model;
  final int programId;

  const _CourseFormScreen({this.model, required this.programId});

  @override
  State<_CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends State<_CourseFormScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _numberCtrl;

  bool _saving = false;
  late final CourseService _service;

  @override
  void initState() {
    super.initState();
    _service = CourseService(Supabase.instance.client);
    _nameCtrl = TextEditingController(text: widget.model?.name ?? '');
    _numberCtrl = TextEditingController(
      text: (widget.model?.courseNumber ?? 1).toString(),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final number = int.tryParse(_numberCtrl.text) ?? 1;
    final course = CourseModel(
      id: widget.model?.id ?? 0,
      programId: widget.programId,
      courseNumber: number,
      name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
    );

    setState(() => _saving = true);
    try {
      if (widget.model == null) {
        await _service.create(course);
      } else {
        await _service.update(widget.model!.id, course);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.model == null ? 'Добавить курс' : 'Редактировать курс',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _numberCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Номер курса',
                hintText: '1',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Название (опционально)',
                hintText: 'Например: Первый курс',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
