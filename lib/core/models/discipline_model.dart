class DisciplineModel {
  final int id;
  final String name;
  final String? description;
  final int hoursPerWeek;

  DisciplineModel({
    required this.id,
    required this.name,
    this.description,
    required this.hoursPerWeek,
  });

  factory DisciplineModel.fromJson(Map<String, dynamic> json) {
    return DisciplineModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      hoursPerWeek: json['hours_per_week'] as int? ?? 2,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'hours_per_week': hoursPerWeek,
  };
}
