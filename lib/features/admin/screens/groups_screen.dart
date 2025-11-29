import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/group_model.dart';
import '../../../core/models/program_model.dart';
import '../../../core/models/course_model.dart';
import '../../../core/services/group_service.dart';
import '../../../core/services/program_service.dart';
import '../../../core/services/course_service.dart';
import '../../../core/services/student_service.dart';
import '../../../core/models/student_model.dart';
import 'group_disciplines_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
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
      final groups = await _groupService.fetchAll();
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
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки групп: $e')));
    }
  }

  Future<void> _openAdd([GroupModel? model]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _GroupFormScreen(model: model, programs: _programs),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _delete(int id) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Удалить группу?'),
            content: const Text(
              'Все студенты будут разрегистрированы из группы.',
            ),
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
      await _groupService.delete(id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
    }
  }

  void _viewStudents(GroupModel group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _GroupStudentsScreen(group: group)),
    );
  }

  void _manageDisciplines(GroupModel group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GroupDisciplinesScreen(group: group)),
    );
  }

  String _getCourseName(GroupModel group) {
    if (group.courseId == null) return '❌ Без курса';
    try {
      final program = _programs.firstWhere((p) => p.id == group.programId);
      return 'Курс ${group.courseId}/${program.durationYears}';
    } catch (_) {
      return 'Курс ${group.courseId}';
    }
  }

  String _getStatusBadge(GroupModel group) {
    switch (group.status) {
      case 'active':
        return '🟢 Активна';
      case 'graduated':
        return '✅ Выпущена';
      case 'archived':
        return '🔒 Архивирована';
      default:
        return group.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Управление группами')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final groupedByProgram = <int?, List<GroupModel>>{};
    for (final g in _groups) {
      final pid = g.programId;
      if (!groupedByProgram.containsKey(pid)) {
        groupedByProgram[pid] = [];
      }
      groupedByProgram[pid]!.add(g);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Управление группами')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(),
        shape: const StadiumBorder(),
        child: const Icon(Icons.add),
      ),
      body: _groups.isEmpty
          ? const Center(child: Text('Групп нет. Добавьте первую группу.'))
          : ListView(
              padding: const EdgeInsets.all(8),
              children: groupedByProgram.entries.map((entry) {
                final programId = entry.key;
                final groupsList = entry.value;

                ProgramModel? program;
                if (programId != null) {
                  try {
                    program = _programs.firstWhere((p) => p.id == programId);
                  } catch (_) {
                    program = null;
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (program != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                        child: Text(
                          '📚 ${program.name}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ...groupsList.map((g) {
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(
                            g.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                g.specialization ?? 'Специализация не указана',
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(_getCourseName(g)),
                                  const SizedBox(width: 12),
                                  Text(_getStatusBadge(g)),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                onTap: () => _viewStudents(g),
                                child: const Text('👥 Студенты'),
                              ),
                              PopupMenuItem(
                                onTap: () => _manageDisciplines(g),
                                child: const Text('📖 Дисциплины группы'),
                              ),
                              PopupMenuItem(
                                onTap: () => _openAdd(g),
                                child: const Text('✏️ Редактировать'),
                              ),
                              PopupMenuItem(
                                onTap: () => _delete(g.id),
                                child: const Text('🗑️ Удалить'),
                              ),
                            ],
                          ),
                          onTap: () => _viewStudents(g),
                        ),
                      );
                    }).toList(),
                  ],
                );
              }).toList(),
            ),
    );
  }
}

class _GroupStudentsScreen extends StatefulWidget {
  final GroupModel group;

  const _GroupStudentsScreen({required this.group});

  @override
  State<_GroupStudentsScreen> createState() => _GroupStudentsScreenState();
}

class _GroupStudentsScreenState extends State<_GroupStudentsScreen> {
  List<StudentModel> _students = [];
  bool _loading = true;

  late final StudentService _studentService;

  @override
  void initState() {
    super.initState();
    _studentService = StudentService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final students = await _studentService.fetchByGroup(widget.group.id);
      setState(() {
        _students = students;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Студенты: ${widget.group.name}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
          ? const Center(child: Text('В этой группе нет студентов'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _students.length,
              itemBuilder: (context, i) {
                final s = _students[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(s.fullName[0].toUpperCase()),
                    ),
                    title: Text(s.fullName),
                    subtitle: Text(s.email ?? 'нет email'),
                    trailing: Text(s.phone ?? 'нет телефона'),
                  ),
                );
              },
            ),
    );
  }
}

class _GroupFormScreen extends StatefulWidget {
  final GroupModel? model;
  final List<ProgramModel> programs;

  const _GroupFormScreen({this.model, required this.programs});

  @override
  State<_GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends State<_GroupFormScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _specCtrl;
  late final TextEditingController _yearCtrl;

  int? _selectedProgramId;
  int? _selectedCourseId;
  List<CourseModel> _coursesForProgram = [];
  bool _coursesLoading = false;

  bool _saving = false;
  late final GroupService _service;
  late final CourseService _courseService;

  @override
  void initState() {
    super.initState();
    _service = GroupService(Supabase.instance.client);
    _courseService = CourseService(Supabase.instance.client);

    _nameCtrl = TextEditingController(text: widget.model?.name ?? '');
    _specCtrl = TextEditingController(text: widget.model?.specialization ?? '');
    _yearCtrl = TextEditingController(
      text: (widget.model?.yearStarted ?? 2024).toString(),
    );

    _selectedProgramId = widget.model?.programId;
    _selectedCourseId = widget.model?.courseId;

    if (_selectedProgramId != null) {
      _loadCoursesForProgram(_selectedProgramId!);
    }
  }

  Future<void> _loadCoursesForProgram(int programId) async {
    setState(() => _coursesLoading = true);
    try {
      final courses = await _courseService.fetchByProgram(programId);
      setState(() {
        _coursesForProgram = courses;
        _coursesLoading = false;
      });
    } catch (e) {
      setState(() => _coursesLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки курсов: $e')));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _specCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите название группы')));
      return;
    }

    if (_selectedProgramId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите направление')));
      return;
    }

    final year = int.tryParse(_yearCtrl.text) ?? 2024;
    final group = GroupModel(
      id: widget.model?.id ?? 0,
      name: name,
      specialization: _specCtrl.text.trim().isEmpty
          ? null
          : _specCtrl.text.trim(),
      yearStarted: year,
      programId: _selectedProgramId,
      courseId: _selectedCourseId,
    );

    setState(() => _saving = true);
    try {
      if (widget.model == null) {
        await _service.create(group);
      } else {
        await _service.update(widget.model!.id, group);
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
          widget.model == null ? 'Добавить группу' : 'Редактировать группу',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Направление
            DropdownButtonFormField<int?>(
              value: _selectedProgramId,
              decoration: const InputDecoration(
                labelText: 'Программа/направление *',
                prefixIcon: Icon(Icons.school),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Выберите направление'),
                ),
                ...widget.programs.map(
                  (p) =>
                      DropdownMenuItem<int?>(value: p.id, child: Text(p.name)),
                ),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedProgramId = val;
                  _selectedCourseId = null;
                });
                if (val != null) {
                  _loadCoursesForProgram(val);
                }
              },
            ),
            const SizedBox(height: 16),

            // Курс
            if (_coursesLoading)
              const CircularProgressIndicator()
            else
              DropdownButtonFormField<int?>(
                value: _selectedCourseId,
                decoration: const InputDecoration(
                  labelText: 'Курс *',
                  prefixIcon: Icon(Icons.trending_up),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Выберите курс'),
                  ),
                  ..._coursesForProgram.map(
                    (c) => DropdownMenuItem<int?>(
                      value: c.id,
                      child: Text(c.name ?? '${c.courseNumber}-й курс'),
                    ),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedCourseId = val),
              ),
            const SizedBox(height: 16),

            // Название группы
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Название группы *',
                prefixIcon: Icon(Icons.people),
                hintText: 'Например: ПИ-101',
              ),
            ),
            const SizedBox(height: 16),

            // Специализация
            TextField(
              controller: _specCtrl,
              decoration: const InputDecoration(
                labelText: 'Специализация',
                prefixIcon: Icon(Icons.work),
                hintText: 'Например: Программирование',
              ),
            ),
            const SizedBox(height: 16),

            // Год начала
            TextField(
              controller: _yearCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Год начала',
                prefixIcon: Icon(Icons.calendar_today),
                hintText: '2024',
              ),
            ),
            const SizedBox(height: 32),

            // Кнопка сохранения
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
