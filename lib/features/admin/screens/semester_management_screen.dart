import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/semester_model.dart';
import '../../../core/models/group_model.dart';
import '../../../core/models/discipline_model.dart';
import '../../../core/services/group_service.dart';
import '../../../core/services/group_semester_service.dart';
import '../../../core/services/semester_discipline_service.dart';
import '../../../core/services/discipline_service.dart';

class SemesterManagementScreen extends StatefulWidget {
  final SemesterModel semester;

  const SemesterManagementScreen({required this.semester});

  @override
  State<SemesterManagementScreen> createState() =>
      _SemesterManagementScreenState();
}

class _SemesterManagementScreenState extends State<SemesterManagementScreen> {
  int _currentTab = 0; // 0 = группы, 1 = дисциплины

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Управление семестром №${widget.semester.semesterNumber}',
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Группы'),
              Tab(text: 'Дисциплины'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _GroupsTab(semester: widget.semester),
            _DisciplinesTab(semester: widget.semester),
          ],
        ),
      ),
    );
  }
}

class _GroupsTab extends StatefulWidget {
  final SemesterModel semester;

  const _GroupsTab({required this.semester});

  @override
  State<_GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<_GroupsTab> {
  List<GroupModel> _allGroups = [];
  List<int> _groupsInSemester = [];
  bool _loading = true;

  late final GroupService _groupService;
  late final GroupSemesterService _groupSemesterService;

  @override
  void initState() {
    super.initState();
    _groupService = GroupService(Supabase.instance.client);
    _groupSemesterService = GroupSemesterService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final allGroups = await _groupService.fetchAll();
      final inSemester = await _groupSemesterService.fetchGroupsInSemester(
        widget.semester.id,
      );
      setState(() {
        _allGroups = allGroups;
        _groupsInSemester = inSemester;
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

  Future<void> _assignGroup(int groupId) async {
    try {
      await _groupSemesterService.assignGroupToSemester(
        groupId,
        widget.semester.id,
      );
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Группа назначена на семестр')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _allGroups.length,
      itemBuilder: (context, i) {
        final g = _allGroups[i];
        final assigned = _groupsInSemester.contains(g.id);

        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(g.name),
            subtitle: Text(g.specialization ?? 'нет специализации'),
            trailing: assigned
                ? const Icon(Icons.check_circle, color: Colors.green)
                : ElevatedButton(
                    onPressed: () => _assignGroup(g.id),
                    child: const Text('Назначить'),
                  ),
          ),
        );
      },
    );
  }
}

class _DisciplinesTab extends StatefulWidget {
  final SemesterModel semester;

  const _DisciplinesTab({required this.semester});

  @override
  State<_DisciplinesTab> createState() => _DisciplinesTabState();
}

class _DisciplinesTabState extends State<_DisciplinesTab> {
  List<DisciplineModel> _allDisciplines = [];
  List<DisciplineModel> _semesterDisciplines = [];
  bool _loading = true;

  late final DisciplineService _disciplineService;
  late final SemesterDisciplineService _semesterDisciplineService;

  @override
  void initState() {
    super.initState();
    _disciplineService = DisciplineService(Supabase.instance.client);
    _semesterDisciplineService = SemesterDisciplineService(
      Supabase.instance.client,
    );
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final all = await _disciplineService.fetchAll();
      final forSemester = await _semesterDisciplineService.fetchForSemester(
        widget.semester.id,
      );
      setState(() {
        _allDisciplines = all;
        _semesterDisciplines = forSemester;
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

  Future<void> _addDiscipline() async {
    final notAssigned = _allDisciplines
        .where((d) => !_semesterDisciplines.any((sd) => sd.id == d.id))
        .toList();

    if (notAssigned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Все дисциплины уже назначены')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Добавить дисциплину'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: notAssigned.length,
            itemBuilder: (context, i) {
              final d = notAssigned[i];
              return ListTile(
                title: Text(d.name),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await _semesterDisciplineService.assignDiscipline(
                      widget.semester.id,
                      d.id,
                    );
                    _load();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeDiscipline(int disciplineId) async {
    try {
      await _semesterDisciplineService.removeDiscipline(
        widget.semester.id,
        disciplineId,
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: ElevatedButton(
            onPressed: _addDiscipline,
            child: const Text('+ Добавить дисциплину'),
          ),
        ),
        Expanded(
          child: _semesterDisciplines.isEmpty
              ? const Center(child: Text('Дисциплин нет'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _semesterDisciplines.length,
                  itemBuilder: (context, i) {
                    final d = _semesterDisciplines[i];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(d.name),
                        subtitle: Text('${d.hoursPerWeek} ч/нед'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeDiscipline(d.id),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
