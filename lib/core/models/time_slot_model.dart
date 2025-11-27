class TimeSlotModel {
  final int id;
  final int slotNumber; // номер пары 1..N
  final int weekday; // 1..7
  final String startTime; // "08:30:00"
  final String endTime; // "09:15:00"
  final int breakAfter; // перемена после пары, минуты
  final String? description;
  final bool isActive;

  TimeSlotModel({
    required this.id,
    required this.slotNumber,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.breakAfter,
    required this.isActive,
    this.description,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      id: json['id'] as int,
      slotNumber: int.tryParse(json['slot_number'].toString()) ?? 1,
      weekday: int.tryParse(json['weekday'].toString()) ?? 1,
      startTime: json['start_time'].toString(),
      endTime: json['end_time'].toString(),
      breakAfter: int.tryParse(json['break_after']?.toString() ?? '0') ?? 0,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'slot_number': slotNumber,
    'weekday': weekday,
    'start_time': startTime,
    'end_time': endTime,
    'break_after': breakAfter,
    'description': description,
    'is_active': isActive,
  };

  TimeSlotModel copyWith({
    int? id,
    int? slotNumber,
    int? weekday,
    String? startTime,
    String? endTime,
    int? breakAfter,
    String? description,
    bool? isActive,
  }) {
    return TimeSlotModel(
      id: id ?? this.id,
      slotNumber: slotNumber ?? this.slotNumber,
      weekday: weekday ?? this.weekday,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breakAfter: breakAfter ?? this.breakAfter,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}
