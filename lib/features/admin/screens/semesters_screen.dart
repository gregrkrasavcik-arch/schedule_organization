import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/program_model.dart';
import '../../../core/models/semester_model.dart';
import '../../../core/services/semester_service.dart';
import 'semester_management_screen.dart';

class SemestersScreen extends StatefulWidget {
  final ProgramModel program;

  const SemestersScreen({required this.program});

  @override
  State<SemestersScreen> createState() => _SemestersScreenState();
}

class _SemestersScreenState extends State<SemestersScreen> {
  List<SemesterModel> _semesters = [];
  bool _loading = true;

  late final SemesterService _service;

  @override
  void initState() {
    super.initState();
    _service = SemesterService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final semesters = await _service.fetchByProgram(widget.program.id);
      setState(() {
        _semesters = semesters;
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

  Future<void> _openAdd([SemesterModel? model]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _SemesterFormScreen(model: model, programId: widget.program.id),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _delete(int id) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Удалить семестр?'),
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

  void _manageSemester(SemesterModel semester) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SemesterManagementScreen(semester: semester),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Семестры: ${widget.program.name}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(),
        shape: const StadiumBorder(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _semesters.isEmpty
          ? const Center(child: Text('Семестров нет'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _semesters.length,
              itemBuilder: (context, i) {
                final s = _semesters[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(s.name ?? 'Семестр ${s.semesterNumber}'),
                    subtitle: Text('№${s.semesterNumber}'),
                    trailing: PopupMenuButton(
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          onTap: () => _manageSemester(s),
                          child: const Text('Управление'),
                        ),
                        PopupMenuItem(
                          onTap: () => _openAdd(s),
                          child: const Text('Редактировать'),
                        ),
                        PopupMenuItem(
                          onTap: () => _delete(s.id),
                          child: const Text('Удалить'),
                        ),
                      ],
                    ),
                    onTap: () => _manageSemester(s),
                  ),
                );
              },
            ),
    );
  }
}

class _SemesterFormScreen extends StatefulWidget {
  final SemesterModel? model;
  final int programId;

  const _SemesterFormScreen({this.model, required this.programId});

  @override
  State<_SemesterFormScreen> createState() => _SemesterFormScreenState();
}

class _SemesterFormScreenState extends State<_SemesterFormScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _numberCtrl;

  bool _saving = false;
  late final SemesterService _service;

  @override
  void initState() {
    super.initState();
    _service = SemesterService(Supabase.instance.client);
    _nameCtrl = TextEditingController(text: widget.model?.name ?? '');
    _numberCtrl = TextEditingController(
      text: (widget.model?.semesterNumber ?? 1).toString(),
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
    final semester = SemesterModel(
      id: widget.model?.id ?? 0,
      programId: widget.programId,
      semesterNumber: number,
      name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
    );

    setState(() => _saving = true);
    try {
      if (widget.model == null) {
        await _service.create(semester);
      } else {
        await _service.update(widget.model!.id, semester);
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
          widget.model == null ? 'Добавить семестр' : 'Редактировать семестр',
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
                labelText: 'Номер семестра',
                hintText: '1',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Название (опционально)',
                hintText: 'Например: Осень 2024',
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
