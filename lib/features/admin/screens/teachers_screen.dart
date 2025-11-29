import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/teacher_model.dart';
import '../../../core/services/teacher_service.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  List<TeacherModel> _teachers = [];
  bool _loading = true;

  late final TeacherService _service;

  @override
  void initState() {
    super.initState();
    _service = TeacherService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final teachers = await _service.fetchAll();
      setState(() {
        _teachers = teachers;
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

  Future<void> _openAdd([TeacherModel? model]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _TeacherFormScreen(model: model)),
    );
    if (result == true) _load();
  }

  Future<void> _delete(int id) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Удалить преподавателя?'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Управление преподавателями')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(),
        shape: const StadiumBorder(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _teachers.isEmpty
          ? const Center(child: Text('Преподавателей нет. Добавьте первого.'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _teachers.length,
              itemBuilder: (context, i) {
                final t = _teachers[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(t.fullName),
                    subtitle: Text(
                      '${t.specialization ?? "Нет специализации"} • ${t.maxHoursPerWeek} ч/нед',
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          onTap: () => _openAdd(t),
                          child: const Text('Редактировать'),
                        ),
                        PopupMenuItem(
                          onTap: () => _delete(t.id),
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

class _TeacherFormScreen extends StatefulWidget {
  final TeacherModel? model;

  const _TeacherFormScreen({this.model});

  @override
  State<_TeacherFormScreen> createState() => _TeacherFormScreenState();
}

class _TeacherFormScreenState extends State<_TeacherFormScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _specCtrl;
  late final TextEditingController _hoursCtrl;

  bool _saving = false;
  late final TeacherService _service;

  @override
  void initState() {
    super.initState();
    _service = TeacherService(Supabase.instance.client);
    _nameCtrl = TextEditingController(text: widget.model?.fullName ?? '');
    _emailCtrl = TextEditingController(text: widget.model?.email ?? '');
    _phoneCtrl = TextEditingController(text: widget.model?.phone ?? '');
    _specCtrl = TextEditingController(text: widget.model?.specialization ?? '');
    _hoursCtrl = TextEditingController(
      text: (widget.model?.maxHoursPerWeek ?? 30).toString(),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _specCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите ФИО')));
      return;
    }

    final hours = int.tryParse(_hoursCtrl.text) ?? 30;
    final teacher = TeacherModel(
      id: widget.model?.id ?? 0,
      fullName: name,
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      specialization: _specCtrl.text.trim().isEmpty
          ? null
          : _specCtrl.text.trim(),
      maxHoursPerWeek: hours,
    );

    setState(() => _saving = true);
    try {
      if (widget.model == null) {
        await _service.create(teacher);
      } else {
        await _service.update(widget.model!.id, teacher);
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
              ? 'Добавить преподавателя'
              : 'Редактировать преподавателя',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'ФИО'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Телефон'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _specCtrl,
              decoration: const InputDecoration(labelText: 'Специализация'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hoursCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Максимум часов в неделю',
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
