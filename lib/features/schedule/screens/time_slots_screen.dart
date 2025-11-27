import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/time_slot_model.dart';
import '../../../core/services/time_slot_service.dart';

class TimeSlotsScreen extends StatefulWidget {
  const TimeSlotsScreen({super.key});

  @override
  State<TimeSlotsScreen> createState() => _TimeSlotsScreenState();
}

class _TimeSlotsScreenState extends State<TimeSlotsScreen> {
  final _dayNames = const [
    '',
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
    'Воскресенье',
  ];

  late final TimeSlotService _service;
  bool _loading = true;
  List<TimeSlotModel> _slots = [];

  @override
  void initState() {
    super.initState();
    _service = TimeSlotService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.fetchAll();
      setState(() {
        _slots = data;
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

  int get _currentWeekdayForCopy {
    if (_slots.isEmpty) return 1;
    return _slots.first.weekday;
  }

  Future<void> _applySchoolTemplate() async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Применить школьный шаблон?'),
            content: const Text(
              'Будут перезаписаны существующие слоты для всех будних дней (Пн–Пт).',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Применить'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    final client = Supabase.instance.client;

    final baseTimes = <Map<String, String>>[
      {'start': '08:30:00', 'end': '09:15:00'},
      {'start': '09:25:00', 'end': '10:10:00'},
      {'start': '10:20:00', 'end': '11:05:00'},
      {'start': '11:25:00', 'end': '12:10:00'},
      {'start': '12:20:00', 'end': '13:05:00'},
      {'start': '13:15:00', 'end': '14:00:00'},
    ];

    final slots = <Map<String, dynamic>>[];

    for (var weekday = 1; weekday <= 5; weekday++) {
      for (var i = 0; i < baseTimes.length; i++) {
        slots.add({
          'slot_number': i + 1,
          'weekday': weekday,
          'start_time': baseTimes[i]['start'],
          'end_time': baseTimes[i]['end'],
          'break_after': 10,
          'description': null,
          'is_active': true,
        });
      }
    }

    await client.from('time_slots').delete().neq('id', -1);
    await client.from('time_slots').insert(slots);
    _load();
  }

  Future<void> _copyCurrentDayToWeekdays() async {
    if (_slots.isEmpty) return;

    final day = _currentWeekdayForCopy;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Копировать слоты?'),
            content: Text(
              'Скопировать слоты ${_dayNames[day]} на все будние дни (Пн–Пт)?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Копировать'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    final client = Supabase.instance.client;
    final source = _slots.where((s) => s.weekday == day).toList();
    if (source.isEmpty) return;

    // удаляем все будние (1–5)
    for (final w in [1, 2, 3, 4, 5]) {
      await client.from('time_slots').delete().eq('weekday', w);
    }

    final toInsert = <Map<String, dynamic>>[];
    for (var weekday = 1; weekday <= 5; weekday++) {
      for (final s in source) {
        toInsert.add({
          'slot_number': s.slotNumber,
          'weekday': weekday,
          'start_time': s.startTime,
          'end_time': s.endTime,
          'break_after': s.breakAfter,
          'description': s.description,
          'is_active': s.isActive,
        });
      }
    }

    await client.from('time_slots').insert(toInsert);
    _load();
  }

  Future<void> _editSlot({TimeSlotModel? slot}) async {
    final isNew = slot == null;
    final model =
        slot ??
        TimeSlotModel(
          id: 0,
          slotNumber: 1,
          weekday: 1,
          startTime: '08:30:00',
          endTime: '09:15:00',
          breakAfter: 10,
          isActive: true,
        );

    final result = await showDialog<TimeSlotModel>(
      context: context,
      builder: (_) =>
          _TimeSlotDialog(initial: model, dayNames: _dayNames, isNew: isNew),
    );

    if (result != null) {
      await _service.upsert(result);
      _load();
    }
  }

  Future<void> _deleteSlot(TimeSlotModel slot) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Удалить слот?'),
            content: Text(
              'Удалить ${slot.slotNumber}-ю пару (${_dayNames[slot.weekday]})?',
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
    await _service.delete(slot.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Временные слоты'),
        actions: [
          IconButton(
            tooltip: 'Школьный шаблон',
            icon: const Icon(Icons.auto_fix_high),
            onPressed: _applySchoolTemplate,
          ),
          IconButton(
            tooltip: 'Копировать день на будни',
            icon: const Icon(Icons.copy_all),
            onPressed: _copyCurrentDayToWeekdays,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editSlot(),
        child: const Icon(Icons.add),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: const [
              Color(0xFF1A237E),
              Color(0xFF1565C0),
              Color(0xFF0D47A1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _slots.isEmpty
              ? const Center(
                  child: Text(
                    'Пока нет ни одного временного слота',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _slots.length,
                  itemBuilder: (context, index) {
                    final s = _slots[index];
                    final day = _dayNames[s.weekday];
                    final subtitle =
                        '$day • ${s.startTime.substring(0, 5)}–${s.endTime.substring(0, 5)}'
                        ' • перемена ${s.breakAfter} мин';

                    return _GlassTile(
                      onTap: () => _editSlot(slot: s),
                      onLongPress: () => _deleteSlot(s),
                      title: '${s.slotNumber}-я пара',
                      subtitle: subtitle,
                      description: s.description,
                      active: s.isActive,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _GlassTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? description;
  final bool active;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _GlassTile({
    required this.title,
    required this.subtitle,
    required this.active,
    this.description,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final accent = active ? Colors.tealAccent : Colors.grey;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.black.withOpacity(0.25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [accent, accent.withOpacity(0.3)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                        if (description != null && description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    active ? Icons.check_circle : Icons.cancel,
                    size: 20,
                    color: active ? accent : Colors.redAccent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeSlotDialog extends StatefulWidget {
  final TimeSlotModel initial;
  final List<String> dayNames;
  final bool isNew;

  const _TimeSlotDialog({
    required this.initial,
    required this.dayNames,
    required this.isNew,
  });

  @override
  State<_TimeSlotDialog> createState() => _TimeSlotDialogState();
}

class _TimeSlotDialogState extends State<_TimeSlotDialog> {
  late int _slotNumber;
  late int _weekday;
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  late TextEditingController _breakCtrl;
  late TextEditingController _descCtrl;
  bool _active = true;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _slotNumber = widget.initial.slotNumber;
    _weekday = widget.initial.weekday;
    _startCtrl = TextEditingController(
      text: widget.initial.startTime.substring(0, 5),
    );
    _endCtrl = TextEditingController(
      text: widget.initial.endTime.substring(0, 5),
    );
    _breakCtrl = TextEditingController(
      text: widget.initial.breakAfter.toString(),
    );
    _descCtrl = TextEditingController(text: widget.initial.description ?? '');
    _active = widget.initial.isActive;
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    _breakCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final slot = widget.initial.copyWith(
      slotNumber: _slotNumber,
      weekday: _weekday,
      startTime: '${_startCtrl.text}:00',
      endTime: '${_endCtrl.text}:00',
      breakAfter: int.tryParse(_breakCtrl.text.trim()) ?? 0,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      isActive: _active,
    );

    Navigator.pop(context, slot);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isNew ? 'Новый слот' : 'Редактировать слот'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'День недели'),
                value: _weekday,
                onChanged: (v) => setState(() => _weekday = v ?? 1),
                items: List.generate(
                  7,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text(widget.dayNames[index + 1]),
                  ),
                ),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Номер пары'),
                initialValue: _slotNumber.toString(),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    _slotNumber = int.tryParse(v.trim()) ?? _slotNumber,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Начало (HH:MM)',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Обязательно'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _endCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Конец (HH:MM)',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Обязательно'
                          : null,
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _breakCtrl,
                decoration: const InputDecoration(
                  labelText: 'Перемена после (минут)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Комментарий'),
              ),
              SwitchListTile(
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                title: const Text('Активен'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Сохранить')),
      ],
    );
  }
}
