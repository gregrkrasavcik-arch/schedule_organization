import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/discipline_model.dart';
import '../../../core/models/group_model.dart';
import '../../../core/services/discipline_service.dart';
import '../../../core/services/group_discipline_service.dart';

class GroupDisciplinesScreen extends StatefulWidget {
  final GroupModel group;

  const GroupDisciplinesScreen({required this.group});

  @override
  State<GroupDisciplinesScreen> createState() => _GroupDisciplinesScreenState();
}

class _GroupDisciplinesScreenState extends State<GroupDisciplinesScreen> {
  List<DisciplineModel> _allDisciplines = [];
  List<DisciplineModel> _groupDisciplines = [];
  bool _loading = true;

  late final DisciplineService _disciplineService;
  late final GroupDisciplineService _groupDisciplineService;

  @override
  void initState() {
    super.initState();
    _disciplineService = DisciplineService(Supabase.instance.client);
    _groupDisciplineService = GroupDisciplineService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final all = await _disciplineService.fetchAll();
      final forGroup = await _groupDisciplineService.fetchForGroup(
        widget.group.id,
      );
      setState(() {
        _allDisciplines = all;
        _groupDisciplines = forGroup;
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

  Future<void> _addDiscipline() async {
    final notAssigned = _allDisciplines
        .where((d) => !_groupDisciplines.any((gd) => gd.id == d.id))
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
                    await _groupDisciplineService.assignDiscipline(
                      widget.group.id,
                      d.id,
                      isCommon: false,
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
      await _groupDisciplineService.removeDiscipline(
        widget.group.id,
        disciplineId,
      );
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
      appBar: AppBar(title: Text('Дисциплины: ${widget.group.name}')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDiscipline,
        shape: const StadiumBorder(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groupDisciplines.isEmpty
          ? const Center(child: Text('Дисциплины не назначены'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _groupDisciplines.length,
              itemBuilder: (context, i) {
                final d = _groupDisciplines[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(d.name),
                    subtitle: Text(d.hoursPerWeek.toString() + ' ч/нед'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeDiscipline(d.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
