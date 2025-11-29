import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/schedule_model.dart';
import '../../../core/services/profile_service.dart';
import '../../admin/screens/admin_screen.dart';
import '../../auth/screens/profile_screen.dart';
import 'schedule_add_screen.dart';
import 'time_slots_screen.dart';
import 'schedule_rules_screen.dart';

class ScheduleListScreen extends StatefulWidget {
  const ScheduleListScreen({super.key});

  @override
  State<ScheduleListScreen> createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends State<ScheduleListScreen> {
  List<ScheduleModel> _items = [];
  bool _isLoading = true;

  String _role = 'student';

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

  final _emptyMessages = const [
    'Сегодня отдыхаем — пар нет 🎓',
    'Тишина в расписании. Можно заняться чем-то полезным.',
    'Ни одной пары. Идеальный день для проектов.',
    'Расписание пусто — время для саморазвития.',
  ];

  final _dayColors = const [
    Color(0xFF1E88E5), // Пн
    Color(0xFF43A047), // Вт
    Color(0xFF8E24AA), // Ср
    Color(0xFFFB8C00), // Чт
    Color(0xFF5E35B1), // Пт
    Color(0xFF00897B), // Сб
    Color(0xFF546E7A), // Вс
  ];

  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _loadRole();
    _load();
  }

  Future<void> _loadRole() async {
    final service = ProfileService(Supabase.instance.client);
    final r = await service.fetchRole();
    if (!mounted) return;
    setState(() => _role = r);
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final client = Supabase.instance.client;
    try {
      final data = await client
          .from('schedule')
          .select()
          .order('date', ascending: true)
          .order('weekday', ascending: true)
          .order('slot_number', ascending: true)
          .order('start_time', ascending: true);

      final list = (data as List)
          .map((e) => ScheduleModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      setState(() {
        _items = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
    }
  }

  Future<void> _openAdd([ScheduleModel? model]) async {
    Map<String, dynamic>? initial;
    if (model != null) {
      initial = model.toJson();
      initial['id'] = model.id;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleAddScreen(initialData: initial),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _delete(int id) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Удалить занятие?'),
            content: const Text('Эту операцию нельзя будет отменить.'),
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

    final client = Supabase.instance.client;
    try {
      await client.from('schedule').delete().eq('id', id);
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
    final Map<int, List<ScheduleModel>> byDay = {
      for (var i = 1; i <= 7; i++) i: [],
    };
    for (final m in _items) {
      final w = (m.weekday >= 1 && m.weekday <= 7) ? m.weekday : 1;
      byDay[w]!.add(m);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Расписание колледжа'),
        backgroundColor: Colors.transparent,
        actions: [
          if (_role == 'admin') ...[
            IconButton(
              tooltip: 'Администратор',
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminScreen()),
                );
              },
            ),
            IconButton(
              tooltip: 'Слоты',
              icon: const Icon(Icons.access_time),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TimeSlotsScreen()),
                );
              },
            ),
            IconButton(
              tooltip: 'Настройки нагрузки',
              icon: const Icon(Icons.tune),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScheduleRulesScreen(),
                  ),
                );
              },
            ),
          ],
          IconButton(
            tooltip: 'Профиль',
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _role == 'admin'
          ? FloatingActionButton(
              onPressed: () => _openAdd(),
              shape: const StadiumBorder(),
              child: const Icon(Icons.add),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: const [Color(0xFF1A237E), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;

                      int columns;
                      if (width > 1200) {
                        columns = 4;
                      } else if (width > 900) {
                        columns = 3;
                      } else if (width > 600) {
                        columns = 2;
                      } else {
                        columns = 1;
                      }

                      if (columns == 1) {
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(8, 16, 8, 90),
                          itemCount: 7,
                          itemBuilder: (context, index) {
                            final day = index + 1;
                            return _DayColumn(
                              weekday: day,
                              title: _dayNames[day],
                              color: _dayColors[(day - 1) % _dayColors.length],
                              items: byDay[day]!,
                              canEdit: _role == 'admin',
                              onTapItem: _openAdd,
                              onLongPressItem: _delete,
                              emptyMessage:
                                  _emptyMessages[_rand.nextInt(
                                    _emptyMessages.length,
                                  )],
                              maxHeight: null,
                            );
                          },
                        );
                      }

                      final itemWidth = width / columns - 12;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(8, 16, 8, 90),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(7, (i) {
                            final day = i + 1;
                            return SizedBox(
                              width: itemWidth,
                              child: _DayColumn(
                                weekday: day,
                                title: _dayNames[day],
                                color:
                                    _dayColors[(day - 1) % _dayColors.length],
                                items: byDay[day]!,
                                canEdit: _role == 'admin',
                                onTapItem: _openAdd,
                                onLongPressItem: _delete,
                                emptyMessage:
                                    _emptyMessages[_rand.nextInt(
                                      _emptyMessages.length,
                                    )],
                                maxHeight: 320,
                              ),
                            );
                          }),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final msg = _emptyMessages[_rand.nextInt(_emptyMessages.length)];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 18),
        ),
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  final int weekday;
  final String title;
  final Color color;
  final List<ScheduleModel> items;
  final bool canEdit;
  final void Function(ScheduleModel) onTapItem;
  final void Function(int id) onLongPressItem;
  final String emptyMessage;
  final double? maxHeight;

  const _DayColumn({
    required this.weekday,
    required this.title,
    required this.color,
    required this.items,
    required this.canEdit,
    required this.onTapItem,
    required this.onLongPressItem,
    required this.emptyMessage,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final totalLoad = items.fold<int>(
      0,
      (sum, m) => sum + m.loadScore.clamp(1, 5),
    );
    final maxLoad = (items.length * 5).clamp(1, 40);
    final loadRatio = items.isEmpty
        ? 0.0
        : (totalLoad / maxLoad).clamp(0.0, 1.0);

    Widget content;
    if (items.isEmpty) {
      content = Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Text(
          emptyMessage,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      );
    } else if (maxHeight == null) {
      content = Column(children: items.map((m) => _buildCard(m)).toList());
    } else {
      content = Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(children: items.map((m) => _buildCard(m)).toList()),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxHeight ?? double.infinity,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.20),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: color.computeLuminance() > 0.4
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                        ),
                        content,
                      ],
                    ),
                  ),
                  Container(
                    width: 10,
                    margin: const EdgeInsets.only(right: 6),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withOpacity(0.12),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: loadRatio,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.greenAccent.withOpacity(0.4),
                                    Colors.redAccent.withOpacity(0.9),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(ScheduleModel m) {
    final accent = parseHexColor(
      m.subjectColor,
      fallback: color.withOpacity(0.8),
    );
    final dateStr = m.date != null ? DateFormat('dd.MM').format(m.date!) : '';
    final timeRange = '${m.startTime} — ${m.endTime}';
    final pairNumber = (m.slotNumber ?? 0) > 0 ? m.slotNumber.toString() : '';

    return _GlassCard(
      accentColor: accent,
      pairNumber: pairNumber,
      title: m.lessonName.isEmpty ? 'Без названия' : m.lessonName,
      subtitleLines: [
        [
          if (pairNumber.isNotEmpty) '$pairNumber‑я пара',
          if (dateStr.isNotEmpty) dateStr,
        ].join(' · '),
        'Преподаватель: ${m.teacher.isEmpty ? 'не указан' : m.teacher}',
        'Аудитория: ${m.classroom.isEmpty ? 'не указана' : m.classroom}',
      ],
      timeRange: timeRange,
      onTap: canEdit ? () => onTapItem(m) : null,
      onLongPress: canEdit ? () => onLongPressItem(m.id) : null,
    );
  }
}

class _GlassCard extends StatefulWidget {
  final String title;
  final List<String> subtitleLines;
  final String timeRange;
  final String pairNumber;
  final Color accentColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _GlassCard({
    required this.title,
    required this.subtitleLines,
    required this.timeRange,
    required this.pairNumber,
    required this.accentColor,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  @override
  State<_GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<_GlassCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: _hover ? 1 : 0.96,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: InkWell(
                  onTap: widget.onTap,
                  onLongPress: widget.onLongPress,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.accentColor.withOpacity(_hover ? 0.7 : 0.55),
                          Colors.black.withOpacity(0.10),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.20),
                        width: 1,
                      ),
                      boxShadow: _hover
                          ? [
                              BoxShadow(
                                color: widget.accentColor.withOpacity(0.5),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.accentColor,
                          ),
                          child: Center(
                            child: Text(
                              widget.pairNumber.isEmpty
                                  ? '•'
                                  : widget.pairNumber,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              ...widget.subtitleLines.map(
                                (line) => Text(
                                  line,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.timeRange,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
    );
  }
}
