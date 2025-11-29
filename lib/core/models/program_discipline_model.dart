class ProgramDisciplineModel {
  final int id;
  final int programId;
  final int disciplineId;

  ProgramDisciplineModel({
    required this.id,
    required this.programId,
    required this.disciplineId,
  });

  factory ProgramDisciplineModel.fromJson(Map<String, dynamic> json) {
    return ProgramDisciplineModel(
      id: json['id'] as int,
      programId: json['program_id'] as int,
      disciplineId: json['discipline_id'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'program_id': programId,
    'discipline_id': disciplineId,
  };
}
