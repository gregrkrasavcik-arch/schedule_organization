import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/program_model.dart';
import '../../../core/services/program_service.dart';
import 'courses_screen.dart';
import 'program_disciplines_screen.dart';

class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key});

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  List<ProgramModel> _programs = [];
  bool _loading = true;

  late final ProgramService _service;

  @override
  void initState() {
    super.initState();
    _service = ProgramService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final programs = await _service.fetchAll();
      setState(() {
        _programs = programs;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
    }
  }

  Future<void> _openAdd([ProgramModel? model]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _ProgramFormScreen(model: model)),
    );
    if (result == true) _load();
  }

  Future<void> _delete(int id) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Удалить направление?'),
            content: const Text('Это действие нельзя отменить.'),
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
      ).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
    }
  }

  void _manageCourses(ProgramModel program) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CoursesScreen(program: program)),
    );
  }

  void _manageDisciplines(ProgramModel program) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProgramDisciplinesScreen(program: program),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Управление направлениями')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(),
        shape: const StadiumBorder(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _programs.isEmpty
          ? const Center(child: Text('Направлений нет. Добавьте первое.'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _programs.length,
              itemBuilder: (context, i) {
                final p = _programs[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(p.name),
                    subtitle: Text(
                      '${p.durationYears} лет • ${p.description ?? "нет описания"}',
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          onTap: () => _manageCourses(p),
                          child: const Text('Курсы'),
                        ),
                        PopupMenuItem(
                          onTap: () => _manageDisciplines(p),
                          child: const Text('Дисциплины направления'),
                        ),
                        PopupMenuItem(
                          onTap: () => _openAdd(p),
                          child: const Text('Редактировать'),
                        ),
                        PopupMenuItem(
                          onTap: () => _delete(p.id),
                          child: const Text('Удалить'),
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

class _ProgramFormScreen extends StatefulWidget {
  final ProgramModel? model;

  const _ProgramFormScreen({this.model});

  @override
  State<_ProgramFormScreen> createState() => _ProgramFormScreenState();
}

class _ProgramFormScreenState extends State<_ProgramFormScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _yearsCtrl;

  bool _saving = false;
  late final ProgramService _service;

  @override
  void initState() {
    super.initState();
    _service = ProgramService(Supabase.instance.client);
    _nameCtrl = TextEditingController(text: widget.model?.name ?? '');
    _descCtrl = TextEditingController(text: widget.model?.description ?? '');
    _yearsCtrl = TextEditingController(
      text: (widget.model?.durationYears ?? 4).toString(),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _yearsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название направления')),
      );
      return;
    }

    final years = int.tryParse(_yearsCtrl.text) ?? 4;
    final program = ProgramModel(
      id: widget.model?.id ?? 0,
      name: name,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      durationYears: years,
    );

    setState(() => _saving = true);
    try {
      if (widget.model == null) {
        await _service.create(program);
      } else {
        await _service.update(widget.model!.id, program);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.model == null
              ? 'Добавить направление'
              : 'Редактировать направление',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Название направления',
                hintText: 'Например: Программирование',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Описание'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _yearsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Продолжительность (лет)',
                hintText: '4',
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
