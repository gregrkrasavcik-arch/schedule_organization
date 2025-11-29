import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/discipline_model.dart';
import '../../../core/services/discipline_service.dart';

class DisciplinesScreen extends StatefulWidget {
  const DisciplinesScreen({super.key});

  @override
  State<DisciplinesScreen> createState() => _DisciplinesScreenState();
}

class _DisciplinesScreenState extends State<DisciplinesScreen> {
  List<DisciplineModel> _disciplines = [];
  bool _loading = true;

  late final DisciplineService _service;

  @override
  void initState() {
    super.initState();
    _service = DisciplineService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final disciplines = await _service.fetchAll();
      setState(() {
        _disciplines = disciplines;
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

  Future<void> _openAdd([DisciplineModel? model]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _DisciplineFormScreen(model: model)),
    );
    if (result == true) _load();
  }

  Future<void> _delete(int id) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Удалить дисциплину?'),
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
      appBar: AppBar(title: const Text('Управление дисциплинами')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(),
        shape: const StadiumBorder(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _disciplines.isEmpty
          ? const Center(child: Text('Дисциплин нет. Добавьте первую.'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _disciplines.length,
              itemBuilder: (context, i) {
                final d = _disciplines[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(d.name),
                    subtitle: Text(
                      '${d.hoursPerWeek} ч/нед • ${d.description ?? "нет описания"}',
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          onTap: () => _openAdd(d),
                          child: const Text('Редактировать'),
                        ),
                        PopupMenuItem(
                          onTap: () => _delete(d.id),
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

class _DisciplineFormScreen extends StatefulWidget {
  final DisciplineModel? model;

  const _DisciplineFormScreen({this.model});

  @override
  State<_DisciplineFormScreen> createState() => _DisciplineFormScreenState();
}

class _DisciplineFormScreenState extends State<_DisciplineFormScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _hoursCtrl;

  bool _saving = false;
  late final DisciplineService _service;

  @override
  void initState() {
    super.initState();
    _service = DisciplineService(Supabase.instance.client);
    _nameCtrl = TextEditingController(text: widget.model?.name ?? '');
    _descCtrl = TextEditingController(text: widget.model?.description ?? '');
    _hoursCtrl = TextEditingController(
      text: (widget.model?.hoursPerWeek ?? 2).toString(),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название дисциплины')),
      );
      return;
    }

    final hours = int.tryParse(_hoursCtrl.text) ?? 2;
    final discipline = DisciplineModel(
      id: widget.model?.id ?? 0,
      name: name,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      hoursPerWeek: hours,
    );

    setState(() => _saving = true);
    try {
      if (widget.model == null) {
        await _service.create(discipline);
      } else {
        await _service.update(widget.model!.id, discipline);
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
              ? 'Добавить дисциплину'
              : 'Редактировать дисциплину',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Название дисциплины',
                hintText: 'Например: Математика',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Описание'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hoursCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Часов в неделю'),
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
