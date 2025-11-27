import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/schedule_rules_model.dart';
import '../../../core/services/schedule_rules_service.dart';

class ScheduleRulesScreen extends StatefulWidget {
  const ScheduleRulesScreen({super.key});

  @override
  State<ScheduleRulesScreen> createState() => _ScheduleRulesScreenState();
}

class _ScheduleRulesScreenState extends State<ScheduleRulesScreen> {
  late final ScheduleRulesService _service;
  ScheduleRules? _rules;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = ScheduleRulesService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await _service.fetch();
    setState(() {
      _rules = r;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_rules == null) return;
    await _service.save(_rules!);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Настройки сохранены')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _rules == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final r = _rules!;
    final hardDays = r.hardDays.toSet();
    final dayNames = const ['', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки нагрузки')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Максимальная нагрузка в день'),
                Slider(
                  value: r.maxLoadPerDay.toDouble(),
                  min: 4,
                  max: 20,
                  divisions: 16,
                  label: r.maxLoadPerDay.toString(),
                  onChanged: (v) {
                    setState(() {
                      _rules = ScheduleRules(
                        id: r.id,
                        maxLoadPerDay: v.round(),
                        maxPairsPerDay: r.maxPairsPerDay,
                        hardDays: r.hardDays,
                      );
                    });
                  },
                ),
                const SizedBox(height: 8),
                const Text('Максимум пар в день'),
                Slider(
                  value: r.maxPairsPerDay.toDouble(),
                  min: 4,
                  max: 10,
                  divisions: 6,
                  label: r.maxPairsPerDay.toString(),
                  onChanged: (v) {
                    setState(() {
                      _rules = ScheduleRules(
                        id: r.id,
                        maxLoadPerDay: r.maxLoadPerDay,
                        maxPairsPerDay: v.round(),
                        hardDays: r.hardDays,
                      );
                    });
                  },
                ),
                const SizedBox(height: 12),
                const Text('Дни с повышенной нагрузкой'),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (i) {
                    if (i == 0) return const SizedBox.shrink();
                    final selected = hardDays.contains(i);
                    return ChoiceChip(
                      label: Text(dayNames[i]),
                      selected: selected,
                      onSelected: (_) {
                        final newSet = hardDays.toSet();
                        if (selected) {
                          newSet.remove(i);
                        } else {
                          newSet.add(i);
                        }
                        setState(() {
                          _rules = ScheduleRules(
                            id: r.id,
                            maxLoadPerDay: r.maxLoadPerDay,
                            maxPairsPerDay: r.maxPairsPerDay,
                            hardDays: newSet.toList(),
                          );
                        });
                      },
                    );
                  }),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Сохранить'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
