import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/schedule_model.dart';
import '../../../core/models/time_slot_model.dart';
import '../../../core/services/time_slot_service.dart';

class ScheduleAddScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const ScheduleAddScreen({super.key, this.initialData});

  @override
  State<ScheduleAddScreen> createState() => _ScheduleAddScreenState();
}

class _ScheduleAddScreenState extends State<ScheduleAddScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _lessonCtrl;
  late TextEditingController _teacherCtrl;
  late TextEditingController _classroomCtrl;
  late TextEditingController _startTimeCtrl;
  late TextEditingController _endTimeCtrl;

  int _weekday = 1; // 1–7, вычисляется по дате
  int _slotNumber = 1; // номер пары
  int _loadScore = 1; // 1–5
  DateTime? _date;
  String? _selectedColorHex;

  bool _isSaving = false;
  bool _slotsLoading = false;
  List<TimeSlotModel> _slotsForDay = [];

  late final TimeSlotService _slotService;

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

  final _availableColors = const [
    '#42A5F5',
    '#66BB6A',
    '#FFA726',
    '#AB47BC',
    '#EF5350',
  ];

  @override
  void initState() {
    super.initState();
    _slotService = TimeSlotService(Supabase.instance.client);

    final data = widget.initialData;
    _lessonCtrl = TextEditingController(text: data?['lesson_name'] ?? '');
    _teacherCtrl = TextEditingController(text: data?['teacher'] ?? '');
    _classroomCtrl = TextEditingController(text: data?['classroom'] ?? '');
    _startTimeCtrl = TextEditingController(
      text: data?['start_time']?.toString() ?? '',
    );
    _endTimeCtrl = TextEditingController(
      text: data?['end_time']?.toString() ?? '',
    );

    _weekday = _parseWeekday(data?['weekday']) ?? DateTime.now().weekday;
    _slotNumber = int.tryParse(data?['slot_number']?.toString() ?? '1') ?? 1;
    _loadScore = int.tryParse(data?['load_score']?.toString() ?? '1') ?? 1;
    _selectedColorHex = data?['subject_color'] as String?;

    if (data?['date'] != null && data!['date'].toString().isNotEmpty) {
      _date = DateTime.tryParse(data['date'].toString());
      if (_date != null) {
        _weekday = _date!.weekday;
      }
    }

    _loadSlotsForDay(_weekday);
  }

  int? _parseWeekday(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Future<void> _loadSlotsForDay(int weekday) async {
    setState(() => _slotsLoading = true);
    try {
      final slots = await _slotService.fetchForWeekday(weekday);
      setState(() {
        _slotsForDay = slots;
        _slotsLoading = false;
      });
    } catch (_) {
      setState(() => _slotsLoading = false);
    }
  }

  @override
  void dispose() {
    _lessonCtrl.dispose();
    _teacherCtrl.dispose();
    _classroomCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
      helpText: 'Выберите дату занятия',
      confirmText: 'Готово',
      cancelText: 'Отмена',
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _weekday = picked.weekday; // авто день недели
      });
      await _loadSlotsForDay(_weekday);
    }
  }

  Future<bool> _checkDailyLoad(int weekday, int newLoadScore) async {
    final client = Supabase.instance.client;
    final data = await client
        .from('schedule')
        .select('load_score')
        .eq('weekday', weekday);

    final existingSum = (data as List)
        .map((e) => int.tryParse(e['load_score']?.toString() ?? '0') ?? 0)
        .fold<int>(0, (sum, v) => sum + v);

    const maxLoadPerDayGost = 10; // временный лимит
    return existingSum + newLoadScore <= maxLoadPerDayGost;
  }

  Future<bool> _saveInternal({required bool closeAfterSave}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return false;
    if (_date == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите дату занятия')));
      return false;
    }

    setState(() => _isSaving = true);

    final ok = await _checkDailyLoad(_weekday, _loadScore);
    if (!ok) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Слишком большая нагрузка на этот день (ограничение по ГОСТ)',
          ),
        ),
      );
      return false;
    }

    final payload = {
      'lesson_name': _lessonCtrl.text.trim(),
      'teacher': _teacherCtrl.text.trim(),
      'classroom': _classroomCtrl.text.trim(),
      'weekday': _weekday,
      'slot_number': _slotNumber,
      'start_time': '${_startTimeCtrl.text.trim()}:00',
      'end_time': '${_endTimeCtrl.text.trim()}:00',
      'date': _date?.toIso8601String(),
      'load_score': _loadScore,
      'subject_color': _selectedColorHex,
    };

    final client = Supabase.instance.client;
    try {
      if (widget.initialData != null && widget.initialData!['id'] != null) {
        await client
            .from('schedule')
            .update(payload)
            .eq('id', widget.initialData!['id']);
      } else {
        await client.from('schedule').insert(payload);
      }

      if (closeAfterSave && mounted) Navigator.pop(context, true);
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveAndClose() async {
    await _saveInternal(closeAfterSave: true);
  }

  Future<void> _saveAndAddAnother() async {
    final ok = await _saveInternal(closeAfterSave: false);
    if (!ok) return;

    setState(() {
      _lessonCtrl.clear();
      _classroomCtrl.clear();
      _startTimeCtrl.clear();
      _endTimeCtrl.clear();
      // дата, день недели, слот, цвет остаются
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пара добавлена, можно ввести следующую')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _date != null
        ? DateFormat('dd.MM.yyyy').format(_date!)
        : 'Выберите дату';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialData == null ? 'Добавить занятие' : 'Изменить занятие',
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueGrey.shade900, Colors.indigo.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _GlassContainer(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _lessonCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Название предмета',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Введите предмет'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _teacherCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Преподаватель',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _classroomCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Аудитория',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Дата занятия',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateText,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _dayNames[_weekday],
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white60,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _pickDate,
                                child: const Text('Выбрать'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _slotsLoading
                              ? const LinearProgressIndicator()
                              : DropdownButtonFormField<int>(
                                  decoration: const InputDecoration(
                                    labelText: 'Номер пары',
                                  ),
                                  value: _slotNumber,
                                  onChanged: (val) {
                                    setState(() => _slotNumber = val ?? 1);

                                    TimeSlotModel? slot;
                                    for (final s in _slotsForDay) {
                                      if (s.slotNumber == _slotNumber) {
                                        slot = s;
                                        break;
                                      }
                                    }
                                    if (slot != null) {
                                      _startTimeCtrl.text = slot.startTime
                                          .substring(0, 5);
                                      _endTimeCtrl.text = slot.endTime
                                          .substring(0, 5);
                                    }
                                  },
                                  items: (() {
                                    final baseNumbers = _slotsForDay.isEmpty
                                        ? List.generate(6, (i) => i + 1)
                                        : _slotsForDay
                                              .map((s) => s.slotNumber)
                                              .toList();
                                    final unique = baseNumbers.toSet().toList()
                                      ..sort();
                                    return unique
                                        .map(
                                          (n) => DropdownMenuItem(
                                            value: n,
                                            child: Text('$n‑я пара'),
                                          ),
                                        )
                                        .toList();
                                  })(),
                                ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _startTimeCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Начало (HH:MM)',
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Введите время'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _endTimeCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Конец (HH:MM)',
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Введите время'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Нагрузка (1–5)',
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                _loadScore.toString(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          Slider(
                            value: _loadScore.toDouble(),
                            min: 1,
                            max: 5,
                            divisions: 4,
                            label: _loadScore.toString(),
                            onChanged: (val) =>
                                setState(() => _loadScore = val.round()),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Цвет предмета',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _availableColors.map((hex) {
                              final color = parseHexColor(hex);
                              final isSelected = _selectedColorHex == hex;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedColorHex = hex),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          )
                                        : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveAndClose,
                                  child: _isSaving
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Сохранить и выйти'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isSaving
                                      ? null
                                      : _saveAndAddAnother,
                                  child: const Text('Добавить ещё пару'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;

  const _GlassContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
