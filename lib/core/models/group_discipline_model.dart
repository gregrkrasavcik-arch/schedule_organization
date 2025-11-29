class GroupDisciplineModel {
  final int id;
  final int groupId;
  final int disciplineId;
  final bool isCommon;

  GroupDisciplineModel({
    required this.id,
    required this.groupId,
    required this.disciplineId,
    required this.isCommon,
  });

  factory GroupDisciplineModel.fromJson(Map<String, dynamic> json) {
    return GroupDisciplineModel(
      id: json['id'] as int,
      groupId: json['group_id'] as int,
      disciplineId: json['discipline_id'] as int,
      isCommon: json['is_common'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'group_id': groupId,
    'discipline_id': disciplineId,
    'is_common': isCommon,
  };
}
