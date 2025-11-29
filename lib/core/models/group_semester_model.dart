class GroupSemesterModel {
  final int id;
  final int groupId;
  final int semesterId;

  GroupSemesterModel({
    required this.id,
    required this.groupId,
    required this.semesterId,
  });

  factory GroupSemesterModel.fromJson(Map<String, dynamic> json) {
    return GroupSemesterModel(
      id: json['id'] as int,
      groupId: json['group_id'] as int,
      semesterId: json['semester_id'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'group_id': groupId,
    'semester_id': semesterId,
  };
}
