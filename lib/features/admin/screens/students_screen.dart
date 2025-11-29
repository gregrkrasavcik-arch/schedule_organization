import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/group_model.dart';
import '../../../core/models/student_model.dart';
import '../../../core/services/group_service.dart';
import '../../../core/services/student_service.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<StudentModel> _students = [];
  List<GroupModel> _groups = [];
  bool _loading = true;
  int? _filterGroupId;

  late final StudentService _studentService;
  late final GroupService _groupService;

  @override
  void initState() {
    super.initState();
    _studentService = StudentService(Supabase.instance.client);
    _groupService = GroupService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final students = await _studentService.fetchAll();
      final groups = await _groupService.fetchAll();
      setState(() {
        _students = students;
        _groups = groups;
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

  Future<void> _openAdd([StudentModel? model]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _StudentFormScreen(model: model, groups: _groups),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _delete(int id) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Удалить студента?'),
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
      await _studentService.delete(id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
    }
  }

  Future<void> _importFromCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось прочитать файл')),
      );
      return;
    }

    try {
      final csvData = String.fromCharCodes(file.bytes!);
      final rows = const CsvToListConverter().convert(csvData);

      if (rows.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Файл пуст')));
        return;
      }

      final students = <StudentModel>[];

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        final fullName = row.length > 0 ? row[0].toString().trim() : '';
        final email = row.length > 1 ? row[1].toString().trim() : '';
        final phone = row.length > 2 ? row[2].toString().trim() : '';
        final groupName = row.length > 3 ? row[3].toString().trim() : '';

        if (fullName.isEmpty) continue;

        int? groupId;
        if (groupName.isNotEmpty) {
          final group = _groups.firstWhere(
            (g) => g.name.toLowerCase() == groupName.toLowerCase(),
            orElse: () => GroupModel(id: 0, name: '', yearStarted: 2024),
          );
          if (group.id != 0) {
            groupId = group.id;
          }
        }

        students.add(
          StudentModel(
            id: 0,
            fullName: fullName,
            email: email.isEmpty ? null : email,
            phone: phone.isEmpty ? null : phone,
            groupId: groupId,
          ),
        );
      }

      if (students.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не найдено валидных студентов')),
        );
        return;
      }

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Подтверждение импорта'),
          content: Text('Готовы добавить ${students.length} студентов?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _studentService.createBatch(students);
                _load();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Добавлено ${students.length} студентов'),
                  ),
                );
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка импорта: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterGroupId == null
        ? _students
        : _students.where((s) => s.groupId == _filterGroupId).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление студентами'),
        actions: [
          PopupMenuButton(
            itemBuilder: (_) => [
              PopupMenuItem(
                onTap: _importFromCsv,
                child: const Text('Импорт из CSV/Excel'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(),
        shape: const StadiumBorder(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Все'),
                        selected: _filterGroupId == null,
                        onSelected: (_) =>
                            setState(() => _filterGroupId = null),
                      ),
                      const SizedBox(width: 8),
                      ..._groups.map((g) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(g.name),
                            selected: _filterGroupId == g.id,
                            onSelected: (_) =>
                                setState(() => _filterGroupId = g.id),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('Студентов нет в этой группе'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final s = filtered[i];
                            final groupName = s.groupId != null
                                ? _groups
                                      .firstWhere(
                                        (g) => g.id == s.groupId,
                                        orElse: () => GroupModel(
                                          id: 0,
                                          name: 'Без группы',
                                          yearStarted: 2024,
                                        ),
                                      )
                                      .name
                                : 'Без группы';

                            return Card(
                              margin: const EdgeInsets.all(8),
                              child: ListTile(
                                title: Text(s.fullName),
                                subtitle: Text(
                                  '$groupName • ${s.email ?? "нет email"}',
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (_) => [
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
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _StudentFormScreen extends StatefulWidget {
  final StudentModel? model;
  final List<GroupModel> groups;

  const _StudentFormScreen({this.model, required this.groups});

  @override
  State<_StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<_StudentFormScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;

  int? _selectedGroupId;
  bool _saving = false;
  late final StudentService _service;

  @override
  void initState() {
    super.initState();
    _service = StudentService(Supabase.instance.client);
    _nameCtrl = TextEditingController(text: widget.model?.fullName ?? '');
    _emailCtrl = TextEditingController(text: widget.model?.email ?? '');
    _phoneCtrl = TextEditingController(text: widget.model?.phone ?? '');
    _selectedGroupId = widget.model?.groupId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
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

    final student = StudentModel(
      id: widget.model?.id ?? 0,
      fullName: name,
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      groupId: _selectedGroupId,
    );

    setState(() => _saving = true);
    try {
      if (widget.model == null) {
        await _service.create(student);
      } else {
        await _service.update(widget.model!.id, student);
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
          widget.model == null ? 'Добавить студента' : 'Редактировать студента',
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
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              value: _selectedGroupId,
              decoration: const InputDecoration(labelText: 'Группа'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Без группы'),
                ),
                ...widget.groups.map(
                  (g) =>
                      DropdownMenuItem<int?>(value: g.id, child: Text(g.name)),
                ),
              ],
              onChanged: (val) => setState(() => _selectedGroupId = val),
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
