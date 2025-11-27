class ScheduleRules {
  final int id;
  final int maxLoadPerDay;
  final int maxPairsPerDay;
  final List<int> hardDays; // 1–7

  ScheduleRules({
    required this.id,
    required this.maxLoadPerDay,
    required this.maxPairsPerDay,
    required this.hardDays,
  });

  factory ScheduleRules.fromJson(Map<String, dynamic> json) {
    final list = (json['hard_days'] as List?) ?? const [];
    return ScheduleRules(
      id: json['id'] as int,
      maxLoadPerDay: int.tryParse(json['max_load_per_day'].toString()) ?? 10,
      maxPairsPerDay: int.tryParse(json['max_pairs_per_day'].toString()) ?? 6,
      hardDays: list.map((e) => int.tryParse(e.toString()) ?? 1).toList(),
    );
  }
}
