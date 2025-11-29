import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/program_model.dart';
import '../../../core/models/discipline_model.dart';
import '../../../core/services/discipline_service.dart';
import '../../../core/services/program_discipline_service.dart';

class ProgramDisciplinesScreen extends StatefulWidget {
  final ProgramModel program;
  const ProgramDisciplinesScreen({required this.program});

  @override
  State<ProgramDisciplinesScreen> createState() =>
      _ProgramDisciplinesScreenState();
}

class _ProgramDisciplinesScreenState extends State<ProgramDisciplinesScreen> {
  List<DisciplineModel> _allDisciplines = [];
  List<DisciplineModel> _programDisciplines = [];
  bool _loading = true;

  late final DisciplineService _disciplineService;
  late final ProgramDisciplineService _programDisciplineService;

  @override
  void initState() {
    super.initState();
    _disciplineService = DisciplineService(Supabase.instance.client);
    _programDisciplineService = ProgramDisciplineService(
      Supabase.instance.client,
    );
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final all = await _disciplineService.fetchAll();
      final forProgram = await _programDisciplineService.fetchForProgram(
        widget.program.id,
      );
      setState(() {
        _allDisciplines = all;
        _programDisciplines = forProgram;
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
        .where((d) => !_programDisciplines.any((gd) => gd.id == d.id))
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
                    await _programDisciplineService.assignDiscipline(
                      widget.program.id,
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
      await _programDisciplineService.removeDiscipline(
        widget.program.id,
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
      appBar: AppBar(title: Text('Дисц. направления: ${widget.program.name}')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDiscipline,
        shape: const StadiumBorder(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _programDisciplines.isEmpty
          ? const Center(child: Text('Дисциплины не назначены'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _programDisciplines.length,
              itemBuilder: (context, i) {
                final d = _programDisciplines[i];
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
    );
  }
}
