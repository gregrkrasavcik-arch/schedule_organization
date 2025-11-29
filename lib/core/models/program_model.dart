class ProgramModel {
  final int id;
  final String name;
  final String? description;
  final int durationYears;

  ProgramModel({
    required this.id,
    required this.name,
    this.description,
    required this.durationYears,
  });

  factory ProgramModel.fromJson(Map<String, dynamic> json) {
    return ProgramModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      durationYears: json['duration_years'] as int? ?? 4,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'duration_years': durationYears,
  };
}
