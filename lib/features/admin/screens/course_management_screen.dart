import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'semester_management_screen.dart';

import '../../../core/models/course_model.dart';
import '../../../core/models/semester_model.dart';
import '../../../core/models/group_model.dart';
import '../../../core/services/semester_service.dart';
import '../../../core/services/group_service.dart';
import 'semesters_screen.dart';

class CourseManagementScreen extends StatefulWidget {
  final CourseModel course;

  const CourseManagementScreen({required this.course});

  @override
  State<CourseManagementScreen> createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  List<SemesterModel> _semesters = [];
  List<GroupModel> _groups = [];
  bool _loading = true;

  late final SemesterService _semesterService;
  late final GroupService _groupService;

  @override
  void initState() {
    super.initState();
    _semesterService = SemesterService(Supabase.instance.client);
    _groupService = GroupService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final semesters = await _semesterService.fetchByCourse(widget.course.id);
      final groups = await _groupService.fetchByCourse(widget.course.id);
      setState(() {
        _semesters = semesters;
        _groups = groups;
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Курс ${widget.course.courseNumber}'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Семестры'),
              Tab(text: 'Группы'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _SemestersTab(
                    course: widget.course,
                    semesters: _semesters,
                    onRefresh: _load,
                  ),
                  _GroupsTab(groups: _groups),
                ],
              ),
      ),
    );
  }
}

class _SemestersTab extends StatelessWidget {
  final CourseModel course;
  final List<SemesterModel> semesters;
  final VoidCallback onRefresh;

  const _SemestersTab({
    required this.course,
    required this.semesters,
    required this.onRefresh,
  });

  Future<void> _addSemester() async {
    // Открыть диалог для добавления семестра
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: ElevatedButton(
            onPressed: _addSemester,
            child: const Text('+ Добавить семестр'),
          ),
        ),
        ...semesters.map((s) {
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(s.name ?? 'Семестр ${s.semesterNumber}'),
              subtitle: Text('№${s.semesterNumber}'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SemesterManagementScreen(semester: s),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ],
    );
  }
}

class _GroupsTab extends StatelessWidget {
  final List<GroupModel> groups;

  const _GroupsTab({required this.groups});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: groups.isEmpty
          ? [const Center(child: Text('Групп на этом курсе нет'))]
          : groups.map((g) {
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(g.name),
                  subtitle: Text(g.specialization ?? 'нет специализации'),
                ),
              );
            }).toList(),
    );
  }
}
