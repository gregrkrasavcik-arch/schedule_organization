import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/services/analytics_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late final AnalyticsService _service;
  AnalyticsData? _data;
  bool _loading = true;
  late AnimationController _fadeController;
  late List<AnimationController> _itemControllers;

  @override
  void initState() {
    super.initState();
    _service = AnalyticsService(Supabase.instance.client);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _itemControllers = [];
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _service.getAnalytics();
      setState(() {
        _data = data;
        _loading = false;
        _itemControllers = List.generate(
          4,
          (i) => AnimationController(
            duration: const Duration(milliseconds: 600),
            vsync: this,
          ),
        );
      });

      for (int i = 0; i < _itemControllers.length; i++) {
        await Future.delayed(Duration(milliseconds: i * 100));
        if (mounted) _itemControllers[i].forward();
      }
      if (mounted) _fadeController.forward();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('📊 Аналитика'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
        ),
        backgroundColor: Colors.grey.shade100,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Аналитика'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMetricsGrid(),
            const SizedBox(height: 24),
            if (_data != null) ...[
              _buildLoadChart(),
              const SizedBox(height: 20),
              if (_data!.problems.isNotEmpty) _buildProblemsCard(),
              const SizedBox(height: 20),
              _buildTopGroupsCard(),
              const SizedBox(height: 20),
              _buildTopTeachersCard(),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildAnimatedMetricTile(
          0,
          _data?.totalPairs.toString() ?? '0',
          'Пар',
          Icons.schedule,
          Colors.blue,
        ),
        _buildAnimatedMetricTile(
          1,
          _data?.totalGroups.toString() ?? '0',
          'Групп',
          Icons.groups,
          Colors.green,
        ),
        _buildAnimatedMetricTile(
          2,
          _data?.totalTeachers.toString() ?? '0',
          'Преподов',
          Icons.school,
          Colors.orange,
        ),
        _buildAnimatedMetricTile(
          3,
          _data?.totalStudents.toString() ?? '0',
          'Студентов',
          Icons.person,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildAnimatedMetricTile(
    int index,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    if (index >= _itemControllers.length) {
      return _buildMetricTile(value, label, icon, color);
    }

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _itemControllers[index],
              curve: Curves.easeOut,
            ),
          ),
      child: FadeTransition(
        opacity: _itemControllers[index],
        child: _buildMetricTile(value, label, icon, color),
      ),
    );
  }

  Widget _buildMetricTile(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.28),
                Colors.white.withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.2), color.withOpacity(0.08)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadChart() {
    final dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return _PopUpCard(
      title: '📈 Нагрузка по дням',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            child: Padding(
              padding: const EdgeInsets.only(top: 16, right: 12, bottom: 12),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                itemBuilder: (_, i) {
                  final day = i + 1;
                  final load = _data?.loadByWeekday[day] ?? 0;
                  final maxLoad = (_data?.loadByWeekday.values.isEmpty ?? true)
                      ? 10
                      : _data!.loadByWeekday.values.reduce(
                          (a, b) => a > b ? a : b,
                        );
                  final height = (load * 70 / (maxLoad > 0 ? maxLoad : 1))
                      .toDouble();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 20,
                          child: Text(
                            '$load',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 32,
                          height: height,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: load > 10
                                  ? [Colors.red.shade300, Colors.red.shade600]
                                  : [
                                      Colors.blue.shade300,
                                      Colors.blue.shade600,
                                    ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: (load > 10 ? Colors.red : Colors.blue)
                                    .withOpacity(0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          dayNames[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade300, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Норма',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade300, Colors.red.shade600],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Перегруз',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemsCard() {
    return _PopUpCard(
      title: '⚠️ Проблемы (${_data?.problems.length ?? 0})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: (_data?.problems ?? [])
            .map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  p,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTopGroupsCard() {
    final sorted = (_data?.pairsByGroup.entries.toList() ?? [])
      ..sort((a, b) => b.value.compareTo(a.value));
    return _buildTopCard('👥 Топ групп', sorted.take(5).toList());
  }

  Widget _buildTopTeachersCard() {
    final sorted = (_data?.pairsByTeacher.entries.toList() ?? [])
      ..sort((a, b) => b.value.compareTo(a.value));
    return _buildTopCard('🎓 Топ преподавателей', sorted.take(5).toList());
  }

  Widget _buildTopCard(String title, List<MapEntry<String, int>> items) {
    return _PopUpCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .asMap()
            .entries
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade300, Colors.blue.shade600],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.value.key,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${e.value.value}п',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PopUpCard extends StatefulWidget {
  final String title;
  final Widget child;

  const _PopUpCard({required this.title, required this.child});

  @override
  State<_PopUpCard> createState() => _PopUpCardState();
}

class _PopUpCardState extends State<_PopUpCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.25),
                      Colors.white.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      widget.child,
                    ],
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
