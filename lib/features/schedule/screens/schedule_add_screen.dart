import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/schedule_model.dart';
import '../../../core/models/time_slot_model.dart';
import '../../../core/models/group_model.dart';
import '../../../core/models/teacher_model.dart';
import '../../../core/models/discipline_model.dart';
import '../../../core/services/time_slot_service.dart';
import '../../../core/services/group_service.dart';
import '../../../core/services/teacher_service.dart';
import '../../../core/services/group_semester_service.dart';
import '../../../core/services/semester_discipline_service.dart';
import '../../../core/services/schedule_conflict_service.dart';

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

  int _weekday = 1;
  int _slotNumber = 1;
  int _loadScore = 1;
  DateTime? _date;
  String? _selectedColorHex;
  int? _selectedGroupId;
  int? _selectedTeacherId;
  int? _selectedDisciplineId;

  bool _isSaving = false;
  bool _slotsLoading = false;
  bool _dataLoading = true;

  List<TimeSlotModel> _slotsForDay = [];
  List<GroupModel> _groups = [];
  List<TeacherModel> _teachers = [];
  List<DisciplineModel> _availableDisciplines = [];

  late final TimeSlotService _slotService;
  late final GroupService _groupService;
  late final TeacherService _teacherService;
  late final GroupSemesterService _groupSemesterService;
  late final SemesterDisciplineService _semesterDisciplineService;
  late final ScheduleConflictService _conflictService;

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
    _groupService = GroupService(Supabase.instance.client);
    _teacherService = TeacherService(Supabase.instance.client);
    _groupSemesterService = GroupSemesterService(Supabase.instance.client);
    _semesterDisciplineService = SemesterDisciplineService(
      Supabase.instance.client,
    );
    _conflictService = ScheduleConflictService(Supabase.instance.client);

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
    _selectedGroupId = data?['group_id'] as int?;
    _selectedTeacherId = data?['teacher_id'] as int?;

    if (data?['date'] != null && data!['date'].toString().isNotEmpty) {
      _date = DateTime.tryParse(data['date'].toString());
      if (_date != null) {
        _weekday = _date!.weekday;
      }
    }

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final groups = await _groupService.fetchAll();
      final teachers = await _teacherService.fetchAll();
      setState(() {
        _groups = groups;
        _teachers = teachers;
        _dataLoading = false;
      });
      await _loadSlotsForDay(_weekday);
      if (_selectedGroupId != null) {
        await _loadDisciplinesForGroup();
      }
    } catch (e) {
      setState(() => _dataLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки данных: $e')));
    }
  }

  Future<void> _loadDisciplinesForGroup() async {
    if (_selectedGroupId == null) {
      setState(() => _availableDisciplines = []);
      return;
    }

    try {
      final semester = await _groupSemesterService.fetchCurrentSemesterForGroup(
        _selectedGroupId!,
      );

      if (semester == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Группа не назначена на семестр')),
        );
        setState(() => _availableDisciplines = []);
        return;
      }

      final disciplines = await _semesterDisciplineService
          .fetchForGroupInSemester(_selectedGroupId!, semester.id);

      setState(() => _availableDisciplines = disciplines);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки дисциплин: $e')));
    }
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
        _weekday = picked.weekday;
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

    const maxLoadPerDayGost = 10;
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

    try {
      // Проверка нагрузки по ГОСТ
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

      // Проверка конфликтов
      final conflicts = await _conflictService.checkAllConflicts(
        groupId: _selectedGroupId,
        teacherId: _selectedTeacherId,
        classroom: _classroomCtrl.text.trim(),
        startTime: '${_startTimeCtrl.text.trim()}:00',
        endTime: '${_endTimeCtrl.text.trim()}:00',
        weekday: _weekday,
        date: _date?.toIso8601String(),
        excludeScheduleId: widget.initialData != null
            ? widget.initialData!['id']
            : null,
      );

      if (conflicts.isNotEmpty) {
        setState(() => _isSaving = false);
        if (!mounted) return false;

        final conflictText = conflicts
            .map((c) => '⚠️ ${c.message}')
            .join('\n\n');

        final proceed =
            await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('🔴 Обнаружены конфликты'),
                content: SingleChildScrollView(child: Text(conflictText)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Отмена'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Добавить всё равно'),
                  ),
                ],
              ),
            ) ??
            false;

        if (!proceed) return false;
        setState(() => _isSaving = true);
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
        'group_id': _selectedGroupId,
        'teacher_id': _selectedTeacherId,
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
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка проверки конфликтов: $e')));
      return false;
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
      _selectedDisciplineId = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Пара добавлена, можно ввести следующую'),
        ),
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
      body: _dataLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
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
                                // Название предмета
                                TextFormField(
                                  controller: _lessonCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Название предмета',
                                    prefixIcon: Icon(Icons.book),
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Введите предмет'
                                      : null,
                                ),
                                const SizedBox(height: 12),

                                // Группа
                                DropdownButtonFormField<int?>(
                                  value: _selectedGroupId,
                                  decoration: const InputDecoration(
                                    labelText: 'Группа',
                                    prefixIcon: Icon(Icons.people),
                                  ),
                                  items: [
                                    const DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text('Без группы'),
                                    ),
                                    ..._groups.map(
                                      (g) => DropdownMenuItem<int?>(
                                        value: g.id,
                                        child: Text(g.name),
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) async {
                                    setState(() => _selectedGroupId = val);
                                    if (val != null) {
                                      await _loadDisciplinesForGroup();
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Дисциплина (если есть дисциплины группы)
                                if (_availableDisciplines.isNotEmpty)
                                  DropdownButtonFormField<int?>(
                                    value: _selectedDisciplineId,
                                    decoration: const InputDecoration(
                                      labelText: 'Дисциплина группы',
                                      prefixIcon: Icon(Icons.bookmark),
                                    ),
                                    items: [
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('Выбрать дисциплину'),
                                      ),
                                      ..._availableDisciplines.map(
                                        (d) => DropdownMenuItem<int?>(
                                          value: d.id,
                                          child: Text(d.name),
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      setState(
                                        () => _selectedDisciplineId = val,
                                      );
                                      if (val != null) {
                                        final discipline = _availableDisciplines
                                            .firstWhere((d) => d.id == val);
                                        _lessonCtrl.text = discipline.name;
                                      }
                                    },
                                  ),
                                const SizedBox(height: 12),

                                // Преподаватель из списка
                                DropdownButtonFormField<int?>(
                                  value: _selectedTeacherId,
                                  decoration: const InputDecoration(
                                    labelText: 'Преподаватель',
                                    prefixIcon: Icon(Icons.school),
                                  ),
                                  items: [
                                    const DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text('Выбрать преподавателя'),
                                    ),
                                    ..._teachers.map(
                                      (t) => DropdownMenuItem<int?>(
                                        value: t.id,
                                        child: Text(t.fullName),
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    setState(() => _selectedTeacherId = val);
                                    if (val != null) {
                                      final teacher = _teachers.firstWhere(
                                        (t) => t.id == val,
                                      );
                                      _teacherCtrl.text = teacher.fullName;
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),

                                // ФИО преподавателя (если не из списка)
                                TextFormField(
                                  controller: _teacherCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'ФИО преподавателя',
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Аудитория
                                TextFormField(
                                  controller: _classroomCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Аудитория',
                                    prefixIcon: Icon(Icons.location_on),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Дата
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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

                                // Номер пары
                                _slotsLoading
                                    ? const LinearProgressIndicator()
                                    : DropdownButtonFormField<int>(
                                        decoration: const InputDecoration(
                                          labelText: 'Номер пары',
                                          prefixIcon: Icon(Icons.schedule),
                                        ),
                                        value: _slotNumber,
                                        onChanged: (val) {
                                          setState(
                                            () => _slotNumber = val ?? 1,
                                          );

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
                                          final baseNumbers =
                                              _slotsForDay.isEmpty
                                              ? List.generate(6, (i) => i + 1)
                                              : _slotsForDay
                                                    .map((s) => s.slotNumber)
                                                    .toList();
                                          final unique =
                                              baseNumbers.toSet().toList()
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

                                // Время
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _startTimeCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Начало (HH:MM)',
                                          prefixIcon: Icon(Icons.schedule),
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
                                          prefixIcon: Icon(Icons.schedule),
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

                                // Нагрузка
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Нагрузка (1–5)',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _loadScore.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
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

                                // Цвет предмета
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Цвет предмета',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
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
                                      onTap: () => setState(
                                        () => _selectedColorHex = hex,
                                      ),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: isSelected
                                              ? Border.all(
                                                  color: Colors.white,
                                                  width: 3,
                                                )
                                              : Border.all(
                                                  color: Colors.white30,
                                                  width: 1,
                                                ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: color.withOpacity(
                                                      0.5,
                                                    ),
                                                    blurRadius: 8,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 24),

                                // Кнопки сохранения
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _isSaving
                                            ? null
                                            : _saveAndClose,
                                        icon: _isSaving
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(Icons.check),
                                        label: const Text('Сохранить и выйти'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _isSaving
                                            ? null
                                            : _saveAndAddAnother,
                                        icon: const Icon(Icons.add),
                                        label: const Text('Ещё пара'),
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
